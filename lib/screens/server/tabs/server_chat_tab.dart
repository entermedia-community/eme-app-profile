import 'dart:async';
import 'dart:convert';
import 'package:eme_world/widgets/delta_viewer.dart';
import 'package:flutter/material.dart' hide FormField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/chat/product_message_card.dart';
import '../../../widgets/chat/session_resume_prompt.dart';
import '../../../widgets/chat/tutorial_cards.dart';
import '../../../widgets/chat/tutorial_picker_sheet.dart';
import 'package:file_picker/file_picker.dart';
import '../../../widgets/chat/chat_attachments.dart';

class ServerChatTab extends ConsumerStatefulWidget {
  final ServerModel server;

  /// When set, chat in this project's team channel (the web project chat
  /// page's channel) instead of the EME Server's channel.
  final String? projectCollectionId;

  /// When set, chat in this event's channel.
  final String? eventId;

  /// When set, opens this earlier session (channel) of the chat instead of
  /// the current one. See Session History.
  final String? initialChannelId;

  const ServerChatTab({
    super.key,
    required this.server,
    this.projectCollectionId,
    this.eventId,
    this.initialChannelId,
  });

  @override
  ConsumerState<ServerChatTab> createState() => _ServerChatTabState();
}

class _ServerChatTabState extends ConsumerState<ServerChatTab> {
  final TextEditingController _textController = TextEditingController();
  final List<PlatformFile> _attachments = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<ChatMessage>? _socketSubscription;
  String _channelId = '';
  bool _isConnecting = false;
  String? _connectionError;
  Map<String, dynamic> _extraData = {};

  /// Last `functionname` seen on a tapped chat link; sent along with later
  /// link posts and typed messages.
  String? _previousFunctionName;

  late List<ChatMessage> _messages;

  // Set when the chat opened in a session left idle for a while: when it was
  // last active. Shows the continue / new session prompt.
  DateTime? _idleSince;
  bool _startingSession = false;

  // Tutorial taken in this chat (null = ordinary server chat). The tutor
  // answers over the socket in its own channel; see _startTutorial.
  TutorialSummary? _tutorial;
  bool _tutorialBusy = false;
  Timer? _tutorialTimer;
  static const _tutorialTimeout = Duration(seconds: 45);
  final Map<String, ({String option, TutorialConfidence confidence})> _answers =
      {};

  @override
  void initState() {
    super.initState();
    _messages = [];
    _initChatConnection();
  }

  Future<void> _initChatConnection() async {
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    final sessionChannel = widget.initialChannelId;
    if (sessionChannel != null) {
      try {
        await _authenticateWithServer();
        await _openChannel(sessionChannel);
      } catch (e, stack) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'Error opening chat session in ServerChatTab',
          customKeys: {'channelId': sessionChannel},
        );
        if (mounted) setState(() => _connectionError = '$e');
      } finally {
        if (mounted) setState(() => _isConnecting = false);
      }
      return;
    }

    final eventId = widget.eventId;
    if (eventId != null) {
      try {
        _channelId = await ref.read(eventChatChannelProvider(eventId).future);
        await _connectSocket(_channelId);
        await _loadChatHistory(_channelId);
      } catch (e, stack) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'Error connecting event chat in ServerChatTab',
          customKeys: {'eventId': eventId},
        );
        if (mounted) setState(() => _connectionError = '$e');
      } finally {
        if (mounted) setState(() => _isConnecting = false);
      }
      return;
    }

    final projectId = widget.projectCollectionId;
    if (projectId != null) {
      try {
        // Asked fresh on every open (not the cached provider): the project's
        // channel comes from librarycollection/connectchat.json.
        final connection = await ref
            .read(apiServiceProvider)
            .connectProjectChat(projectId);
        _channelId = connection.channelId;
        await _connectSocket(_channelId);
        await _loadChatHistory(_channelId);
      } catch (e, stack) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'Error connecting project chat in ServerChatTab',
          customKeys: {'collectionId': projectId},
        );
        if (mounted) setState(() => _connectionError = '$e');
      } finally {
        if (mounted) setState(() => _isConnecting = false);
      }
      return;
    }

    try {
      await _authenticateWithServer();
      final channelId = await ref
          .read(apiServiceProvider)
          .connectServerChat(widget.server.id, baseUrl: _serverBaseUrl);
      await _openChannel(channelId);
      if (mounted) setState(() => _idleSince = idleSince(_messages));
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Error connecting server chat in ServerChatTab',
        customKeys: {'serverId': widget.server.id},
      );
      if (mounted) setState(() => _connectionError = '$e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  // Project and event chats use the app's default server
  String? get _serverBaseUrl =>
      widget.projectCollectionId == null &&
          widget.eventId == null &&
          widget.server.serverMediaDBUrl.isNotEmpty
      ? widget.server.serverMediaDBUrl
      : null;

  /// The user is signed in on the root server (e.g. eme.world), not on this
  /// EME Server (e.g. impactbank.world). Has the server verify our key with
  /// the root and start a session before any chat request goes to it. Skipped
  /// for project/event chats and servers without their own address.
  Future<void> _authenticateWithServer() async {
    final serverUrl = _serverBaseUrl;
    if (serverUrl == null) return;
    await ref.read(authServiceProvider).authenticateRemoteServer(serverUrl);
  }

  /// Points the socket and history at [channelId], reconnecting only when the
  /// channel changed (the socket ignores connect() while already connected).
  Future<void> _openChannel(String channelId, {String? channelType}) async {
    if (channelId == _channelId && ChatSocketService().isConnected) return;
    if (_channelId.isNotEmpty) ChatSocketService().disconnect();
    _channelId = channelId;
    await _connectSocket(
      channelId,
      baseUrl: _serverBaseUrl,
      channelType: channelType,
    );
    await _loadChatHistory(channelId, baseUrl: _serverBaseUrl);
  }

  Future<void> _loadChatHistory(String channelId, {String? baseUrl}) async {
    try {
      final history = await ref
          .read(apiServiceProvider)
          .fetchServerChatMessages(
            channelId,
            serverId: widget.server.id,
            baseUrl: baseUrl,
          );
      if (!mounted) return;
      if (history.isNotEmpty) {
        // Sort chronologically so latest messages appear at the bottom
        history.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        setState(() {
          _messages = history;
        });
        _scrollToBottom();
      }
    } catch (e, stack) {
      debugPrint('Error loading server chat history: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Error loading server chat history in ServerChatTab',
        customKeys: {'channelId': channelId, 'serverId': widget.server.id},
      );
    }
  }

  Future<void> _connectSocket(
    String channelId, {
    String? baseUrl,
    String? channelType,
  }) async {
    final currentUserId = AuthService.userId;
    await ChatSocketService().connect(
      channel: channelId,
      channelType: channelType,
      userId: currentUserId,
      baseUrl: baseUrl,
    );
    _socketSubscription?.cancel();
    _socketSubscription = ChatSocketService().messageStream.listen((
      incomingMsg,
    ) {
      debugPrint('ServerChatTab incomingMsg: ${incomingMsg.toJson()}');
      if (incomingMsg.isKeepAlive) return;
      if (!mounted) return;

      if (incomingMsg.channel.isNotEmpty &&
          incomingMsg.channel != channelId &&
          incomingMsg.channel != widget.server.id) {
        return;
      }

      final added = _mergeIncoming(incomingMsg);
      if (_tutorial != null && !incomingMsg.isUser) _tutorialReplied();
      setState(() {});
      if (added) _scrollToBottom();
    });
  }

  static const _localIdPrefix = 'local_';

  /// Applies a socket message to [_messages] and returns whether it was new.
  /// The server re-sends a message under the same id when it changes (agent
  /// status updates, messagereload), and echoes the ones this device already
  /// shows locally, so both replace the existing entry instead of adding one.
  bool _mergeIncoming(ChatMessage msg) {
    if (msg.isMessageRemoved) {
      _messages.removeWhere((m) => m.messageId == msg.messageId);
      return false;
    }
    var index = _messages.indexWhere((m) => m.messageId == msg.messageId);
    if (index < 0) {
      index = _messages.indexWhere(
        (m) =>
            m.messageId.startsWith(_localIdPrefix) &&
            m.userId == msg.userId &&
            m.message == msg.message,
      );
    }
    if (index < 0) {
      _messages.add(msg);
      return true;
    }
    // The echo may not carry the product card the local copy was built with
    _messages[index] = msg.product == null
        ? msg.copyWith(product: _messages[index].product)
        : msg;
    return false;
  }

  /// Starts a new session in this server chat and moves the chat to it. The
  /// server welcomes the new session itself.
  Future<void> _startNewSession() async {
    setState(() => _startingSession = true);
    try {
      final session = await ref
          .read(apiServiceProvider)
          .createChatSession(
            serverId: widget.server.id,
            baseUrl: _serverBaseUrl,
          );
      if (!mounted) return;
      setState(() {
        _messages = [];
        _idleSince = null;
      });
      await _openChannel(session.channelId);
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Failed to start a new session in ServerChatTab',
        customKeys: {'serverId': widget.server.id},
      );
      _showError('Could not start a new session: $e');
    } finally {
      if (mounted) setState(() => _startingSession = false);
    }
  }

  // ---------------------------------------------------------------------
  // Tutorials
  // ---------------------------------------------------------------------

  bool get _canTakeTutorials =>
      widget.projectCollectionId == null && widget.eventId == null;

  void _showError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.redAccent, content: Text(text)),
    );
  }

  Future<void> _pickTutorial() async {
    final tutorial = await showTutorialPicker(
      context,
      api: ref.read(apiServiceProvider),
      accent: widget.server.primaryColor,
      baseUrl: _serverBaseUrl,
    );
    if (tutorial == null || !mounted) return;
    await _startTutorial(tutorial);
  }

  /// Opens a fresh tutor channel for [tutorial], then asks the tutor to say
  /// its welcome there. Every later step arrives over the socket.
  Future<void> _startTutorial(TutorialSummary tutorial) async {
    final api = ref.read(apiServiceProvider);
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });
    try {
      final session = await api.fetchTutorialSession(
        tutorial.id,
        createNew: true,
        baseUrl: _serverBaseUrl,
      );
      if (!mounted) return;
      setState(() {
        _messages = [];
        _answers.clear();
        _tutorial = tutorial;
      });
      await _openChannel(session.id, channelType: 'agenttutorchat');
      await api.startTutorial(
        tutorial.id,
        channel: session.id,
        baseUrl: _serverBaseUrl,
      );
      _awaitTutor();
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Error starting tutorial in ServerChatTab',
        customKeys: {'tutorialId': tutorial.id, 'serverId': widget.server.id},
      );
      _showError('Could not start the tutorial: $e');
      if (mounted && _tutorial != null) await _exitTutorial();
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  /// Leaves the tutor channel and returns to the server chat.
  Future<void> _exitTutorial() async {
    _tutorialTimer?.cancel();
    setState(() {
      _tutorial = null;
      _tutorialBusy = false;
      _messages = [];
      _answers.clear();
      _isConnecting = true;
      _connectionError = null;
    });
    try {
      await _authenticateWithServer();
      final channelId = await ref
          .read(apiServiceProvider)
          .connectServerChat(widget.server.id, baseUrl: _serverBaseUrl);
      await _openChannel(channelId);
      if (mounted) setState(() => _idleSince = idleSince(_messages));
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Error leaving tutorial in ServerChatTab',
        customKeys: {'serverId': widget.server.id},
      );
      if (mounted) setState(() => _connectionError = '$e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _awaitTutor() {
    _tutorialTimer?.cancel();
    if (mounted) setState(() => _tutorialBusy = true);
    _tutorialTimer = Timer(_tutorialTimeout, () {
      if (!mounted || !_tutorialBusy) return;
      setState(() => _tutorialBusy = false);
      _showError('The tutor did not respond. Try again.');
    });
  }

  void _tutorialReplied() {
    _tutorialTimer?.cancel();
    _tutorialBusy = false;
  }

  /// A message that is bookkeeping rather than conversation: the hidden
  /// progress update and the system commands this device sent.
  bool _isHidden(ChatMessage m) =>
      m.messageRenderType.isProgressUpdate ||
      (m.isUser && m.messageType == 'system');

  /// Where the tutorial stands: the last message that carries a component.
  ChatMessage? get _lastStep {
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].contextValues.componentId != null) return _messages[i];
    }
    return null;
  }

  /// Sends [function] to the tutor. [from] is the step it refers to, the
  /// latest one by default. Returns false (and says why) when it was not sent.
  bool _sendTutorialStep(
    String function, {
    String message = '',
    ChatMessage? from,
    bool system = true,
    Map<String, dynamic> extra = const {},
  }) {
    final tutorial = _tutorial;
    if (tutorial == null || _channelId.isEmpty) return false;
    if (!ChatSocketService().isConnected) {
      _showError('Not connected. Try again in a moment.');
      return false;
    }
    final step = from ?? _lastStep;
    final sectionId = step?.contextValues.sectionId;
    final componentId = step?.contextValues.componentId;
    ChatSocketService().sendMessage(
      message: message,
      user: AuthService.userId ?? 'user',
      channel: _channelId,
      functionName: function,
      command: 'messagereceived',
      messageType: system ? 'system' : 'message',
      extraData: {
        'agentcontext': jsonEncode({
          'tutorialid': tutorial.id,
          'sectionid': ?sectionId,
          'componentid': ?componentId,
          ...extra,
        }),
      },
    );
    _awaitTutor();
    _scrollToBottom();
    return true;
  }

  void _submitAnswer(
    ChatMessage message,
    String option,
    TutorialConfidence confidence,
  ) {
    final question = message.question;
    if (question == null) return;
    final sent = _sendTutorialStep(
      'chat_tutor_answer',
      message: option,
      from: message,
      extra: {
        'messagerendertype': 'answer',
        'questionid': question.id,
        'selectedoption': option,
        'confidence': confidence.name,
      },
    );
    if (sent) {
      setState(
        () => _answers[message.messageId] = (
          option: option,
          confidence: confidence,
        ),
      );
    }
  }

  /// The next visible message after [index], if any.
  ChatMessage? _visibleAfter(int index) {
    for (var i = index + 1; i < _messages.length; i++) {
      if (!_isHidden(_messages[i])) return _messages[i];
    }
    return null;
  }

  Widget _buildTutorialCard(ChatMessage message, bool isDark) {
    final accent = widget.server.primaryColor;
    final type = message.messageRenderType;
    if (type.isQuestion && message.question != null) {
      final index = _messages.indexOf(message);
      final next = _visibleAfter(index);
      final eval = next != null && next.messageRenderType.isAnswerEval
          ? next.contextValues
          : null;
      final local = _answers[message.messageId];
      final answered = local != null || eval != null || next != null;
      return TutorialQuestionCard(
        question: message.question!,
        enabled: !answered && !_tutorialBusy && _tutorial != null,
        reveal: eval != null || local != null,
        selectedOption: local?.option ?? eval?.selectedOption,
        confidence: local?.confidence ?? eval?.confidence,
        accent: accent,
        isDark: isDark,
        onSubmit: (option, confidence) =>
            _submitAnswer(message, option, confidence),
      );
    }
    if (type.isAnswerEval) {
      return TutorialEvalCard(
        text: message.text,
        isCorrect: message.contextValues.isCorrect,
        isDark: isDark,
      );
    }
    if (type.isEnd) {
      return TutorialEndCard(
        text: message.text,
        accent: accent,
        isDark: isDark,
      );
    }
    return const SizedBox.shrink();
  }

  /// The button that moves the tutorial on, or the wait indicator.
  Widget? _buildTutorialFooter(bool isDark) {
    if (_tutorial == null) return null;
    final accent = widget.server.primaryColor;
    if (_tutorialBusy) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
      );
    }
    final visible = _messages.where((m) => !_isHidden(m)).toList();
    if (visible.isEmpty || visible.last.isUser) return null;
    final type = visible.last.messageRenderType;
    final String label;
    if (type.isWelcome) {
      label = 'Start';
    } else if (type.isAsset || type.isAnswerEval || type.isAgentComment) {
      label = 'Continue';
    } else {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Semantics(
          identifier: type.isWelcome ? 'tutorial_start' : 'tutorial_continue',
          child: FilledButton(
            onPressed: () => _sendTutorialStep('chat_tutor_continue'),
            style: FilledButton.styleFrom(backgroundColor: accent),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialBanner(bool isDark) {
    final accent = widget.server.primaryColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      color: accent.withValues(alpha: isDark ? 0.15 : 0.08),
      child: Row(
        children: [
          Icon(Icons.school_outlined, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _tutorial!.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          Semantics(
            identifier: 'tutorial_exit',
            child: TextButton(
              onPressed: _isConnecting ? null : _exitTutorial,
              child: const Text('Exit'),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _tutorialTimer?.cancel();
    ChatSocketService().disconnect();
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void _sendMessage() {
    if (_attachments.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.redAccent,
          content: Text('Sending attachments is not supported yet.'),
        ),
      );
      return;
    }
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (_tutorial != null) {
      _textController.clear();
      _sendTutorialStep(
        'chat_tutor_usercomment',
        message: text,
        system: false,
        extra: {'messagerendertype': 'usercomment', ..._extraData},
      );
      _extraData = {};
      return;
    }

    final targetChannel = _channelId;
    final currentUserId = AuthService.userId ?? 'user';

    setState(() {
      _idleSince = null;
      _textController.clear();
    });

    try {
      if (ChatSocketService().isConnected && targetChannel.isNotEmpty) {
        ChatSocketService().sendMessage(
          message: text,
          user: currentUserId,
          channel: targetChannel,
          command: 'messagereceived',
          functionName: _previousFunctionName ?? '',
          extraData: {"entityid": widget.server.id},
        );
      }
    } catch (e, stack) {
      debugPrint('Failed to send message over socket: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason:
            'Failed to send message over ChatSocketService in ServerChatTab',
      );
    }
  }

  // Kept for the upcoming attach popup (Products / Services entries).
  // ignore: unused_element
  void _sendProduct(ProductMessageModel product) {
    final targetChannel = _channelId;
    final currentUserId = AuthService.userId ?? 'user';

    setState(() {
      _messages.add(
        ChatMessage(
          messageId: '$_localIdPrefix${DateTime.now().millisecondsSinceEpoch}',
          channel: targetChannel,
          userId: currentUserId,
          message:
              'Shared a ${product.typeLabel.toLowerCase()}: ${product.title}',
          messageType: 'product',
          product: product,
          agentContextValues: AgentContextValues(
            messageRenderType: MessageRenderType.product,
            product: product,
          ),
          createdAt: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    try {
      if (ChatSocketService().isConnected && targetChannel.isNotEmpty) {
        ChatSocketService().sendMessage(
          message:
              'Shared a ${product.typeLabel.toLowerCase()}: ${product.title}',
          user: currentUserId,
          channel: targetChannel,
          command: 'messagereceived',
          messageType: 'product',
          extraData: {'product': product.toJson()},
        );
      }
    } catch (e, stack) {
      debugPrint('Failed to send product over socket: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason:
            'Failed to send product over ChatSocketService in ServerChatTab',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final footer = _idleSince != null && _tutorial == null
        ? SessionResumePrompt(
            lastActive: _idleSince!,
            accent: widget.server.primaryColor,
            isDark: isDark,
            busy: _startingSession,
            onContinue: () => setState(() => _idleSince = null),
            onNewSession: _startNewSession,
          )
        : _buildTutorialFooter(isDark);

    return Column(
      children: [
        if (_tutorial != null) _buildTutorialBanner(isDark),
        // Message Feed
        Expanded(
          child: _isConnecting && _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.server.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Connecting to channel...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : _connectionError != null && _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textMuted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Could not open the chat.\n$_connectionError',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        Semantics(
                          identifier: 'server_chat_retry',
                          child: TextButton(
                            onPressed: () {
                              final eventId = widget.eventId;
                              if (eventId != null) {
                                ref.invalidate(
                                  eventChatChannelProvider(eventId),
                                );
                              }
                              final id = widget.projectCollectionId;
                              if (id != null) {
                                ref.invalidate(
                                  projectChatConnectionProvider(id),
                                );
                              }
                              _initChatConnection();
                            },
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _messages.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.chat_bubble_outline_rounded,
                        size: 48,
                        color: isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No messages in ${widget.server.name} yet!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _messages.length + (footer == null ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) return footer!;
                    final msg = _messages[index];
                    return _buildMessageItem(msg, isDark);
                  },
                ),
        ),

        // Input Box
        _buildChatInput(isDark),
      ],
    );
  }

  Widget _buildMessageItem(ChatMessage msg, bool isDark) {
    final isMe = msg.isUser;
    final timeStr = _formatTime(msg.createdAt);

    if (_isHidden(msg)) return const SizedBox.shrink();

    final renderType = msg.messageRenderType;
    if (renderType.isQuestion || renderType.isAnswerEval || renderType.isEnd) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Center(child: _buildTutorialCard(msg, isDark)),
      );
    }

    if (msg.messageRenderType.isForm) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Center(child: _buildFormBubble(msg, timeStr, isDark)),
      );
    }

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: _buildMessageContent(msg, isMe, timeStr, isDark),
                ),
              ],
            ),
            if (msg.messageRenderType.isProduct && msg.product != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ProductMessageCard(product: msg.product!, isMe: true),
              ),
            ],
          ],
        ),
      );
    }

    final senderName = msg.userId.isNotEmpty ? msg.userId : 'Member';
    final senderInitials = senderName.length >= 2
        ? senderName.substring(0, 2).toUpperCase()
        : senderName.toUpperCase();
    final badgeRole = msg.isAI ? 'AI BOT' : 'MEMBER';
    final badgeColor = msg.isAI
        ? AppColors.primary
        : widget.server.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isDark ? 0.3 : 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                senderInitials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      senderName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeRole,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildMessageContent(msg, isMe, timeStr, isDark),
                if (msg.messageRenderType.isProduct && msg.product != null) ...[
                  ProductMessageCard(product: msg.product!, isMe: false),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    ChatMessage message,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    print("*******************");
    debugPrint(
      'ServerChatTab rendering message type: ${message.messageRenderType}',
    );
    print(message.message);
    switch (message.messageRenderType) {
      case MessageRenderType.asset:
        return _buildAssetCard(message, isMe, timeStr, isDark);
      case MessageRenderType.welcome:
        return _buildWelcomeBubble(message, isMe, timeStr, isDark);
      case MessageRenderType.product:
      case MessageRenderType.text:
      case MessageRenderType.agentcomment:
        return _buildStandardBubble(message.text, isMe, timeStr, isDark);
      case MessageRenderType.question:
      case MessageRenderType.answereval:
      case MessageRenderType.end:
      case MessageRenderType.progressupdate:
        return _buildTutorialCard(message, isDark);
      case MessageRenderType.delta:
        return _buildDeltaBubble(message.deltaOps, isMe, timeStr, isDark);
      case MessageRenderType.form:
        return _buildFormBubble(message, timeStr, isDark);
    }
  }

  Widget _buildStandardBubble(
    String text,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? widget.server.primaryColor
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe
            ? null
            : Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
              ),
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isMe
                  ? Colors.white
                  : (isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: isMe
                      ? Colors.white70
                      : (isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textMuted),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  size: 12,
                  color: Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaBubble(
    List<dynamic> deltas,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary
            : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        border: isMe
            ? null
            : Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DeltaViewer(deltaOps: deltas, onLinkTap: _handleLinkTap),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.75)
                      : (isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textMuted),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  size: 13,
                  color: Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBubble(
    ChatMessage message,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.server.primaryColor.withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.server.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.waving_hand_rounded,
                size: 16,
                color: widget.server.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'WELCOME',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: widget.server.primaryColor,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.text,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          if (_canTakeTutorials && _tutorial == null) ...[
            const SizedBox(height: 10),
            Semantics(
              identifier: 'server_chat_tutorials',
              child: OutlinedButton.icon(
                onPressed: _isConnecting ? null : _pickTutorial,
                icon: const Icon(Icons.school_outlined, size: 18),
                label: const Text('Tutorials'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.server.primaryColor,
                  side: BorderSide(color: widget.server.primaryColor),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            timeStr,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormBubble(ChatMessage message, String timeStr, bool isDark) {
    return _ChatFormWidget(
      fields: message.formFields,
      timeStr: timeStr,
      isDark: isDark,
      primaryColor: widget.server.primaryColor,
      onSubmit: (values) => _handleFormSubmit(message, values),
    );
  }

  void _handleFormSubmit(ChatMessage message, Map<String, dynamic> values) {
    final targetChannel = _channelId;
    final currentUserId = AuthService.userId ?? 'user';

    final summary = values.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    final submitText = 'Submitted: $summary';

    setState(() {
      _messages.add(
        ChatMessage(
          messageId: '$_localIdPrefix${DateTime.now().millisecondsSinceEpoch}',
          channel: targetChannel,
          userId: currentUserId,
          message: submitText,
          replyToId: message.messageId,
          createdAt: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    try {
      if (ChatSocketService().isConnected && targetChannel.isNotEmpty) {
        ChatSocketService().sendMessage(
          message: submitText,
          user: currentUserId,
          channel: targetChannel,
          command: 'messagereceived',
          replyToId: message.messageId,
          extraData: {
            'form': values,
            'entityid': widget.server.id,
            'replytoid': message.messageId,
          },
        );
      }
    } catch (e, stack) {
      debugPrint('Failed to send form response over socket: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason:
            'Failed to send form response over ChatSocketService in ServerChatTab',
      );
    }
  }

  Widget _buildAssetCard(
    ChatMessage message,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    final asset = message.asset;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.server.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.attachment_rounded,
              color: widget.server.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset?.mediaType ?? 'Asset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  asset?.url ?? 'Media file',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatAttachmentTray(
              id: 'server_chat',
              files: _attachments,
              onRemove: (f) => setState(() => _attachments.remove(f)),
            ),
            Row(
              children: [
                ChatAttachButton(
                  id: 'server_chat',
                  iconSize: 22,
                  onPicked: (files) =>
                      setState(() => _attachments.addAll(files)),
                ),
                Expanded(
                  child: Semantics(
                    identifier: "server_chat_input",
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textMuted,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : AppColors.lightCardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : AppColors.lightCardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: widget.server.primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: widget.server.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Semantics(
                    identifier: "server_chat_send",
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Last `functionname` found on a link in earlier messages (newest first).
  String? _lookupFunctionNameFromHistory() {
    for (final msg in _messages.reversed) {
      for (final op in msg.deltaOps.reversed) {
        if (op is! Map) continue;
        final attrs = op['attributes'];
        if (attrs is! Map || attrs['link'] == null) continue;
        final fn = attrs['data-functionname']?.toString();
        if (fn != null && fn.isNotEmpty) return fn;
      }
    }
    return null;
  }

  void _handleLinkTap(String link, Map<String, dynamic> data) async {
    debugPrint("Data: $data");
    final funName =
        data['functionname'] ??
        ((_previousFunctionName?.isNotEmpty ?? false)
            ? _previousFunctionName
            : _lookupFunctionNameFromHistory());
    if (link == '#') {
      if (data.containsKey("prefix")) {
        // dispatch a message with prefix as message body + the other data as payload
        ChatSocketService().sendMessage(
          message: data['prefix'],
          user: AuthService.userId ?? 'user',
          channel: _channelId,
          functionName: funName,
          command: 'messagereceived',
        );
        _previousFunctionName = funName;
        return;
      }
    }

    debugPrint("Link: $link");
    if (link.contains("/changescenario.html")) {
      link = '/services/chat/changescenario.json';
    }
    try {
      await ChatSocketService().postChatLink(
        link,
        channel: _channelId,
        data: {...data, 'functionname': ?funName},
        baseUrl: _serverBaseUrl,
      );
      _previousFunctionName = funName;
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Error handling chat link tap in ServerChatTab',
        customKeys: {'serverId': widget.server.id, 'link': link},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open: $e')));
    }
  }
}

class _ChatFormWidget extends StatefulWidget {
  final List<FormField> fields;
  final String timeStr;
  final bool isDark;
  final Color primaryColor;
  final void Function(Map<String, dynamic> values) onSubmit;

  const _ChatFormWidget({
    required this.fields,
    required this.timeStr,
    required this.isDark,
    required this.primaryColor,
    required this.onSubmit,
  });

  @override
  State<_ChatFormWidget> createState() => _ChatFormWidgetState();
}

class _ChatFormWidgetState extends State<_ChatFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _boolValues = {};
  final Map<String, dynamic> _selectValues = {};
  bool _isSubmitted = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    for (final field in widget.fields) {
      final type = field.type.name;
      final isSelect =
          field.type == FormFieldType.select ||
          type == 'select' ||
          type == 'dropdown' ||
          field.options.isNotEmpty;

      if (type == 'bool' || type == 'boolean' || type == 'checkbox') {
        final val = field.value;
        _boolValues[field.name] =
            (val == true || val == 'true' || val == 1 || val == '1');
      } else if (isSelect) {
        dynamic initialValue;
        if (field.value != null) {
          for (final opt in field.options) {
            if (opt.value == field.value ||
                opt.value?.toString() == field.value?.toString()) {
              initialValue = opt.value;
              break;
            }
          }
        }
        _selectValues[field.name] = initialValue;
      } else {
        _controllers[field.name] = TextEditingController(
          text: field.value?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isFormReadOnly {
    final fields = widget.fields;
    if (fields.isEmpty) return true;
    return fields.every((f) => f.readOnly == true);
  }

  Future<void> _pickDate(String fieldName, bool isReadOnly) async {
    if (isReadOnly) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: widget.isDark ? ThemeData.dark() : ThemeData.light(),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _controllers[fieldName]?.text = formatted;
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting || _isSubmitted) return;
    if (!(_formKey.currentState?.validate() ?? true)) return;

    setState(() {
      _isSubmitting = true;
    });

    final Map<String, dynamic> result = {};
    for (final field in widget.fields) {
      final type = field.type.name;
      final isSelect =
          field.type == FormFieldType.select ||
          type == 'select' ||
          type == 'dropdown' ||
          field.options.isNotEmpty;

      if (type == 'bool' || type == 'boolean' || type == 'checkbox') {
        result[field.name] = _boolValues[field.name] ?? false;
      } else if (isSelect) {
        result[field.name] = _selectValues[field.name] ?? '';
      } else {
        result[field.name] = _controllers[field.name]?.text.trim() ?? '';
      }
    }

    widget.onSubmit(result);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        fontSize: 12.5,
        color: widget.isDark ? AppColors.textDarkMuted : AppColors.textMuted,
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 12.5,
        color: widget.isDark ? AppColors.textDarkMuted : AppColors.textMuted,
      ),
      filled: true,
      fillColor: widget.isDark
          ? AppColors.darkCardBorder.withValues(alpha: 0.35)
          : AppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: widget.isDark
              ? AppColors.darkCardBorder
              : AppColors.lightCardBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: widget.isDark
              ? AppColors.darkCardBorder
              : AppColors.lightCardBorder,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color:
              (widget.isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder)
                  .withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
      ),
    );
  }

  Widget _buildFieldWidget(FormField field) {
    final type = field.type.name;
    final name = field.name;
    final label = field.label.isNotEmpty ? field.label : field.name;
    final isFieldReadOnly =
        (field.readOnly == true) || _isFormReadOnly || _isSubmitted;
    final isSelect =
        field.type == FormFieldType.select ||
        type == 'select' ||
        type == 'dropdown' ||
        field.options.isNotEmpty;

    if (type == 'bool' || type == 'boolean' || type == 'checkbox') {
      final isChecked = _boolValues[name] ?? false;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isDark
              ? AppColors.darkCardBorder.withValues(alpha: 0.25)
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Checkbox(
              value: isChecked,
              activeColor: widget.primaryColor,
              onChanged: isFieldReadOnly
                  ? null
                  : (bool? val) {
                      setState(() {
                        _boolValues[name] = val ?? false;
                      });
                    },
            ),
          ],
        ),
      );
    }

    if (isSelect) {
      final seenValues = <dynamic>{};
      final uniqueOptions = <FormFieldOption>[];
      for (final opt in field.options) {
        if (!seenValues.contains(opt.value)) {
          seenValues.add(opt.value);
          uniqueOptions.add(opt);
        }
      }

      final currentValue = _selectValues[name];
      final validValue = seenValues.contains(currentValue)
          ? currentValue
          : null;

      return DropdownButtonFormField<dynamic>(
        initialValue: validValue,
        isExpanded: true,
        dropdownColor: widget.isDark ? AppColors.darkSurface : Colors.white,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: widget.isDark
              ? AppColors.textDarkPrimary
              : AppColors.textPrimary,
        ),
        icon: Icon(
          Icons.arrow_drop_down_rounded,
          color: widget.isDark ? AppColors.textDarkMuted : AppColors.textMuted,
        ),
        hint: Text(
          uniqueOptions.isEmpty ? 'No options available' : 'Select $label',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: widget.isDark
                ? AppColors.textDarkMuted
                : AppColors.textMuted,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        disabledHint: validValue != null
            ? null
            : Text(
                'None selected',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color:
                      (widget.isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textMuted)
                          .withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
        decoration: _buildInputDecoration(labelText: label),
        items: uniqueOptions.map((opt) {
          final optText = opt.label.isNotEmpty
              ? opt.label
              : opt.value?.toString() ?? '';
          return DropdownMenuItem<dynamic>(
            value: opt.value,
            child: Text(
              optText,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: widget.isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: isFieldReadOnly
            ? null
            : (val) {
                setState(() {
                  _selectValues[name] = val;
                });
              },
      );
    }

    if (type == 'date') {
      return TextFormField(
        controller: _controllers[name],
        readOnly: true,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: widget.isDark
              ? AppColors.textDarkPrimary
              : AppColors.textPrimary,
        ),
        onTap: () => _pickDate(name, isFieldReadOnly),
        decoration: _buildInputDecoration(
          labelText: label,
          hintText: 'YYYY-MM-DD',
          suffixIcon: IconButton(
            icon: Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: widget.primaryColor,
            ),
            onPressed: isFieldReadOnly
                ? null
                : () => _pickDate(name, isFieldReadOnly),
          ),
        ),
      );
    }

    final isMultiline =
        type == 'textarea' || type == 'multiline' || type == 'paragraph';
    final isNumber =
        type == 'number' ||
        type == 'int' ||
        type == 'integer' ||
        type == 'decimal' ||
        type == 'float' ||
        type == 'numeric';
    final isPhone = type == 'phone' || type == 'tel';
    final isEmail = type == 'email';
    final isPassword = type == 'password';

    TextInputType keyboardType = TextInputType.text;
    if (isMultiline) {
      keyboardType = TextInputType.multiline;
    } else if (isNumber) {
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
    } else if (isPhone) {
      keyboardType = TextInputType.phone;
    } else if (isEmail) {
      keyboardType = TextInputType.emailAddress;
    }

    return TextFormField(
      controller: _controllers[name],
      readOnly: isFieldReadOnly,
      minLines: isMultiline ? 3 : 1,
      maxLines: isMultiline ? 5 : 1,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: widget.isDark
            ? AppColors.textDarkPrimary
            : AppColors.textPrimary,
      ),
      decoration: _buildInputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hidden fields keep their value in _controllers and are submitted, but never shown
    final fields = widget.fields
        .where((f) => f.type != FormFieldType.hidden)
        .toList();
    final cardBg = widget.isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? AppColors.darkCardBorder
              : AppColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.dynamic_form_rounded,
                    size: 18,
                    color: widget.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Form',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _isSubmitted
                        ? Colors.green.withValues(alpha: 0.15)
                        : (_isFormReadOnly
                              ? (widget.isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.lightCardBorder)
                              : widget.primaryColor.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isSubmitted
                        ? 'SUBMITTED'
                        : (_isFormReadOnly ? 'VIEW ONLY' : 'FORM'),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _isSubmitted
                          ? Colors.green
                          : (_isFormReadOnly
                                ? (widget.isDark
                                      ? AppColors.textDarkMuted
                                      : AppColors.textMuted)
                                : widget.primaryColor),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Form Fields
            if (fields.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'No fields available.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: widget.isDark
                          ? AppColors.textDarkMuted
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              for (int i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _buildFieldWidget(fields[i]),
              ],

            // Submit Button or Submitted Badge
            if (!_isFormReadOnly && !_isSubmitted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ] else if (_isSubmitted) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: widget.isDark ? 0.2 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Submitted successfully',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Time footer
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                widget.timeStr,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: widget.isDark
                      ? AppColors.textDarkMuted
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
