import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:testu_cl/models/chat_message.dart' as socket_msg;
import 'package:testu_cl/models/chat_message.dart';
import 'package:testu_cl/models/topic.dart';
import 'package:testu_cl/services/auth_service.dart';
import 'package:testu_cl/services/chat_socket_service.dart';
import 'package:testu_cl/services/topic_service.dart';
import 'package:testu_cl/widgets/common_widgets.dart';
import 'package:testu_cl/widgets/fullscreen_mediaviewer.dart';
import 'package:testu_cl/widgets/asset_message_widget.dart';
import 'package:transparent_image/transparent_image.dart';

import '../models/tutor_channel.dart';
import '../models/tutorial.dart';
import '../utils/language_helper.dart';

class RehearseScreen extends StatefulWidget {
  final Tutorial tutorial;

  const RehearseScreen({super.key, required this.tutorial});

  @override
  State<RehearseScreen> createState() => _RehearseScreenState();
}

class _RehearseScreenState extends State<RehearseScreen> {
  bool _isLoading = true;
  TutorChannel? _tutorChannel;
  List<RehearseQuestion> _questions = [];
  StreamSubscription<socket_msg.ChatMessage>? _socketSubscription;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _followUpController = TextEditingController();

  int _currentIndex = 0;
  bool _isFinished = false;

  // Track user selections
  // Map index -> selected option index
  final Map<int, int?> _selectedAnswers = {};
  // Map index -> confidence level string ("No Idea", "Not sure", "Mostly Sure", "Confident")
  final Map<int, String?> _confidenceLevels = {};

  final Map<String, String> _confidenceOptions = {
    'noidea': 'No Idea',
    'notsure': 'Not sure',
    'mostlysure': 'Mostly Sure',
    'confident': 'Confident',
  };

  // Chat state
  final List<ChatMessage> _messages = [];
  int? _tempSelectedAnswerIndex;
  String? _tempConfidenceLevel;
  String _stage = 'welcome';

  @override
  void initState() {
    super.initState();
    _loadTutorialDetail();
  }

  Future<void> _loadTutorialDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _messages.clear();
      _questions.clear();

      final channel = await TopicService().fetchTutorChannel(
        widget.tutorial.id,
      );
      if (channel == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _tutorChannel = channel;

      if (_tutorChannel != null) {
        final messageHistory = await TopicService().fetchTutorHistory(
          channelId: _tutorChannel!.id,
        );

        String? lastFoundSectionId;
        String? lastFoundComponentId;
        if (messageHistory.isNotEmpty) {
          _messages.addAll(messageHistory.reversed);

          for (final msg in messageHistory.reversed) {
            if (msg.sectionId != null && msg.sectionId!.isNotEmpty) {
              lastFoundSectionId = msg.sectionId;
            }
            if (msg.componentId != null && msg.componentId!.isNotEmpty) {
              lastFoundComponentId = msg.componentId;
            }
            if (lastFoundSectionId != null && lastFoundComponentId != null) {
              break;
            }
          }
        }

        final userId = AuthService.userId ?? _tutorChannel!.user;

        await ChatSocketService().connect(
          userId: userId,
          channel: _tutorChannel!.id,
        );

        _socketSubscription?.cancel();
        _socketSubscription = ChatSocketService().messageStream.listen((
          incomingMsg,
        ) {
          debugPrint("ChatSocketService incomingMsg: ${incomingMsg.toJson()}");
          if (incomingMsg.isKeepAlive || incomingMsg.isMessageRemoved) return;
          if (incomingMsg.message != null && incomingMsg.message!.isNotEmpty) {
            if (!mounted) return;

            if (incomingMsg.messageType == MessageType.progressupdate) {
              widget.tutorial.progress = TutorialProgress.fromJson(
                incomingMsg.rawJson,
              );
              return;
            }

            setState(() {
              final msgId = incomingMsg.messageId;
              final existingIndex = (msgId != null && msgId.isNotEmpty)
                  ? _messages.indexWhere((m) => m.messageId == msgId)
                  : -1;

              if (existingIndex != -1) {
                // final oldMsg = _messages[existingIndex];
                // if (oldMsg.interactive == false) {
                //   final updatedRaw = Map<String, dynamic>.from(
                //     incomingMsg.rawJson,
                //   );
                //   if (oldMsg.rawJson.containsKey('selected_option_index')) {
                //     updatedRaw['selected_option_index'] =
                //         oldMsg.rawJson['selected_option_index'];
                //   }
                //   incomingMsg = incomingMsg.copyWith(
                //     interactive: false,
                //     rawJson: updatedRaw,
                //   );
                // }
                _messages[existingIndex] = incomingMsg;
              } else {
                _messages.add(
                  ChatMessage(
                    messageId: incomingMsg.messageId,
                    message: incomingMsg.message,
                    messageType: incomingMsg.messageType ?? MessageType.text,
                    userId: incomingMsg.userId,
                    interactive: incomingMsg.interactive,
                    channel:
                        incomingMsg.channel ??
                        (_messages.isNotEmpty ? _messages.last.channel : null),
                    sectionId:
                        incomingMsg.sectionId ??
                        (_messages.isNotEmpty
                            ? _messages.last.sectionId
                            : null),
                    componentId:
                        incomingMsg.componentId ??
                        (_messages.isNotEmpty
                            ? _messages.last.componentId
                            : null),
                    rawJson: incomingMsg.rawJson,
                  ),
                );
              }

              if (incomingMsg.messageType == MessageType.question) {
                debugPrint("$incomingMsg");
                final question = RehearseQuestion.fromChatMessage(incomingMsg);
                final qExistingIndex = (msgId != null && msgId.isNotEmpty)
                    ? _questions.indexWhere(
                        (q) => q.messageId == msgId || q.questionId == msgId,
                      )
                    : -1;

                if (qExistingIndex != -1) {
                  _questions[qExistingIndex] = question;
                } else {
                  _questions.add(question);
                  _currentIndex = _questions.length - 1;
                  _tempSelectedAnswerIndex = null;
                  _tempConfidenceLevel = null;
                  _stage = 'select_option';
                }
              } else if (incomingMsg.messageType == MessageType.end) {
                setState(() {
                  _stage = 'finished';
                });
                _isFinished = true;
              } else {
                setState(() {
                  _stage = 'explain_and_followup';
                });
              }
            });
            _scrollToBottom();
          }
        });

        if (lastFoundSectionId == null || lastFoundComponentId == null) {
          await TopicService().startTutorial(
            tutorialId: widget.tutorial.id,
            channel: _tutorChannel!.id,
          );
        } else {
          _messages.last.sectionId = lastFoundSectionId;
          _messages.last.componentId = lastFoundComponentId;
          setState(() {
            _stage = 'explain_and_followup';
          });
          _scrollToBottom(jump: true);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _questions = [];
        _isLoading = false;
      });
    }
  }

  void _initializeChat() {
    _messages.clear();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _scrollController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (jump) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          return;
        }
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence) {
      case 'noidea':
        return const Color(0xFFF50057); // Soft red
      case 'notsure':
        return const Color(0xFFFF9F43); // Orange
      case 'mostlysure':
        return const Color(0xFF38B6FF); // Light blue
      case 'confident':
        return const Color(0xFF38EF7D); // Vibrant green
      default:
        return Colors.white54;
    }
  }

  void _selectOption(int optIndex) {
    setState(() {
      _tempSelectedAnswerIndex = optIndex;
    });
  }

  void _selectConfidence(String confidence) {
    setState(() {
      _tempConfidenceLevel = confidence;
    });
  }

  void _submitAnswer() {
    if (_tutorChannel == null ||
        _tempSelectedAnswerIndex == null ||
        _tempConfidenceLevel == null) {
      return;
    }

    final activeQuestion =
        _questions.isNotEmpty && _currentIndex < _questions.length
        ? _questions[_currentIndex]
        : null;

    if (activeQuestion == null) {
      return;
    }

    setState(() {
      _selectedAnswers[_currentIndex] = _tempSelectedAnswerIndex;
      _stage = 'explain_and_followup';

      final targetId = activeQuestion.messageId ?? activeQuestion.questionId;
      if (targetId != null && targetId.isNotEmpty) {
        final msgIdx = _messages.indexWhere(
          (m) =>
              m.messageId == targetId ||
              m.rawJson['id']?.toString() == targetId,
        );
        if (msgIdx != -1) {
          final updatedRaw = Map<String, dynamic>.from(
            _messages[msgIdx].rawJson,
          );
          updatedRaw['selected_option_index'] = _tempSelectedAnswerIndex;
          _messages[msgIdx] = _messages[msgIdx].copyWith(
            interactive: false,
            rawJson: updatedRaw,
          );
        }
      }
    });

    TopicService().submitAnswer(
      questionId: activeQuestion.questionId!,
      selectedOption:
          "option_${String.fromCharCode(97 + _tempSelectedAnswerIndex!)}",
      confidence: _tempConfidenceLevel!.toLowerCase().replaceAll(" ", ""),
      channel: _messages.last.channel!,
      sectionId: _messages.last.sectionId!,
      componentId: _messages.last.componentId!,
    );
  }

  void _sendFollowUp() {
    final text = _followUpController.text.trim();
    if (text.isEmpty) return;
    _followUpController.clear();

    final userMsgId = 'user_comment_${DateTime.now().millisecondsSinceEpoch}';

    ChatSocketService().sendMessage(
      message: text,
      messageType: MessageType.usercomment,
      extraData: {
        'context_sectionid': _messages.last.sectionId,
        'context_componentid': _messages.last.componentId,
      },
    );

    setState(() {
      _messages.add(
        ChatMessage(
          messageId: userMsgId,
          userId: AuthService.userId ?? 'user',
          message: text,
          messageType: MessageType.usercomment,
          channel: _messages.last.channel,
          sectionId: _messages.last.sectionId,
          componentId: _messages.last.componentId,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _tutorialContinue() async {
    await TopicService().continueTutorial(
      tutorialId: widget.tutorial.id,
      channel: _messages.last.channel,
      sectionId: _messages.last.sectionId,
      componentId: _messages.last.componentId,
    );
    _scrollToBottom();
  }

  double _calculateScorePercentage() {
    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctAnswerIndex) {
        correctCount++;
      }
    }
    return correctCount / _questions.length;
  }

  int _calculateCorrectCount() {
    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctAnswerIndex) {
        correctCount++;
      }
    }
    return correctCount;
  }

  double _calculateAverageConfidence() {
    if (_confidenceLevels.isEmpty) return 0.0;
    double totalWeight = 0;
    int count = 0;
    _confidenceLevels.forEach((key, val) {
      if (val != null) {
        count++;
        if (val == 'No Idea') totalWeight += 0.25;
        if (val == 'Not sure') totalWeight += 0.50;
        if (val == 'Mostly Sure') totalWeight += 0.75;
        if (val == 'Confident') totalWeight += 1.0;
      }
    });
    return count > 0 ? (totalWeight / count) : 0.0;
  }

  String _getConfidenceTextFromScore(double score) {
    if (score < 0.35) return 'Low Confidence';
    if (score < 0.65) return 'Moderate Confidence';
    if (score < 0.85) return 'High Confidence';
    return 'Strong Confidence';
  }

  Widget _buildRichText(String text, TextStyle baseStyle) {
    String processed = text;

    // Convert common HTML block/line tags
    processed = processed
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li\s*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<h1\s*>', caseSensitive: false), '[h1]')
        .replaceAll(RegExp(r'</h1\s*>', caseSensitive: false), '[/h1]')
        .replaceAll(RegExp(r'</?h[2-6]\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?(div|ul|ol|p)\s*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</?(strong|b)\s*>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'<thumb\s*>', caseSensitive: false), '[thumb]')
        .replaceAll(RegExp(r'</thumb\s*>', caseSensitive: false), '[/thumb]')
        .replaceAll(RegExp(r'<asset\s*>', caseSensitive: false), '[asset]')
        .replaceAll(RegExp(r'</asset\s*>', caseSensitive: false), '[/asset]')
        .replaceAll(RegExp(r'<caption\s*>', caseSensitive: false), '[caption]')
        .replaceAll(
          RegExp(r'</caption\s*>', caseSensitive: false),
          '[/caption]',
        )
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\n\n+'), '\n\n');

    final List<InlineSpan> spans = [];
    final RegExp regExp = RegExp(
      r'\[asset\](.*?)\[/asset\]\s*\[thumb\](.*?)\[/thumb\]\s*(?:\[caption\](.*?)\[/caption\]\s*)?|\[h1\](.*?)\[/h1\]|\*\*(.*?)\*\*',
      dotAll: true,
    );
    int lastMatchEnd = 0;

    for (final Match match in regExp.allMatches(processed)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(text: processed.substring(lastMatchEnd, match.start)),
        );
      }

      final String? assetUrl = match.group(1);
      final String? assetThumb = match.group(2);
      final String? captionText = match.group(3);
      final String? h1Content = match.group(4);
      final String? boldContent = match.group(5);

      if (assetThumb != null && assetUrl != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        FullScreenMediaViewer.open(
                          context,
                          url: assetUrl,
                          caption: captionText,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: assetThumb,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    if (captionText != null &&
                        captionText.trim().isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        captionText.trim(),
                        style: baseStyle.copyWith(
                          fontSize: (baseStyle.fontSize ?? 14.0) - 2.0,
                          color: Colors.white60,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            ),
          ),
        );
      } else if (h1Content != null) {
        spans.add(
          TextSpan(
            text: h1Content.replaceAll('**', ''),
            style: baseStyle.copyWith(
              fontSize: (baseStyle.fontSize ?? 14.0) + 4.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        spans.add(const TextSpan(text: '\n'));
      } else if (boldContent != null) {
        spans.add(
          TextSpan(
            text: boldContent,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < processed.length) {
      spans.add(TextSpan(text: processed.substring(lastMatchEnd)));
    }

    return RichText(
      text: TextSpan(children: spans, style: baseStyle),
    );
  }

  Widget _buildMessageContainer({required bool isAI, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (isAI) ...[
          Container(
            width: 32,
            height: 32,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
              border: Border.all(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image:
                  "https://minsur.genailabs.tech/site/mediadb/services/module/asset/generated/Sources/Iris_Avatar_Minsur/Iris_Avatar_Minsur.png/image200x200.webp",
              imageErrorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.smart_toy, color: Colors.white);
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: isAI
                  ? const Color(0xFF161C24).withValues(alpha: 0.8)
                  : const Color(0xFFF27121).withValues(alpha: 0.15),
              borderRadius: isAI
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
              border: Border.all(
                color: isAI
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF27121).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
        if (!isAI) ...[
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
              border: Border.all(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image:
                  "https://eme.world/mediadb/services/module/asset/generated/Entity%20Assets/profile/placeholder.jpg/image200x200.webp",
              imageErrorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person, color: Colors.white);
              },
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildChatMessageItem(ChatMessage message, bool isLast) {
    switch (message.messageType) {
      case MessageType.welcome:
        return [_buildWelcomeMessage(message, isLast)];
      case MessageType.usercomment:
        return [_buildUserCommentMessage(message)];
      case MessageType.agentcomment:
        return [_buildAgentCommentMessage(message)];
      case MessageType.end:
        return [_buildEndMessage(message)];
      case MessageType.question:
        return [_buildQuestionMessage(message, isLast)];
      case MessageType.questioncontinue:
        return [
          _buildButtonMessage(
            actionButtonLabel: "Continue",
            onPressed: () => _tutorialContinue(),
          ),
        ];
      case MessageType.asset:
        return [_buildAssetMessage(message)];
      case MessageType.text:
      default:
        return [_buildTextMessage(message)];
    }
  }

  Widget _buildAssetMessage(ChatMessage message) {
    return _buildMessageContainer(
      isAI: message.isAI,
      child: AssetMessageWidget(message: message),
    );
  }

  Widget _buildWelcomeMessage(ChatMessage message, bool isLast) {
    return _buildMessageContainer(
      isAI: true,
      child: _buildRichText(
        message.text,
        const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
      ),
    );
  }

  Widget _buildUserCommentMessage(ChatMessage message) {
    return _buildMessageContainer(
      isAI: false,
      child: _buildRichText(
        message.text,
        const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
      ),
    );
  }

  Widget _buildAgentCommentMessage(ChatMessage message) {
    return _buildMessageContainer(
      isAI: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichText(
            message.text,
            TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndMessage(ChatMessage message) {
    return _buildMessageContainer(
      isAI: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF38EF7D),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'COMPLETED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF38EF7D),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildRichText(
            message.text,
            const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(ChatMessage message) {
    return _buildMessageContainer(
      isAI: message.isAI,
      child: _buildRichText(
        message.text,
        TextStyle(
          fontSize: 14,
          color: message.isAI
              ? Colors.white.withValues(alpha: 0.85)
              : Colors.white,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildQuestionMessage(ChatMessage message, bool isLast) {
    final question = RehearseQuestion.fromChatMessage(message);
    final optionLetters = ['A', 'B', 'C', 'D'];
    final bool isInteractive = message.interactive ?? true;

    int? selectedOptIndex;
    if (message.selectedOptionIndex != null) {
      selectedOptIndex = message.selectedOptionIndex;
    } else if (isLast && _tempSelectedAnswerIndex != null) {
      selectedOptIndex = _tempSelectedAnswerIndex;
    }

    final color = _getConfidenceColor(message.confidence?.$1 ?? '');

    return _buildMessageContainer(
      isAI: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text (RichText)
          _buildRichText(
            question.text,
            const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Options (Plain text interactive MCQ)
            Column(
              children: List.generate(question.options.length, (optIndex) {
                final optionText = question.options[optIndex];
                final letter = optIndex < optionLetters.length
                    ? optionLetters[optIndex]
                    : '${optIndex + 1}';
                final isSelected = selectedOptIndex == optIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: InkWell(
                    onTap: isInteractive
                        ? () {
                            _selectOption(optIndex);
                            if (_stage != 'select_option') {
                              setState(() {
                                _stage = 'select_option';
                              });
                            }
                          }
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF27121).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF27121)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFFF27121)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (message.confidence != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${LanguageHelper.translate('confidence')}:",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.confidence!.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildButtonMessage({
    required String actionButtonLabel,
    required Function() onPressed,
  }) {
    return _buildMessageContainer(
      isAI: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF27121),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              actionButtonLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(RehearseQuestion? question) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF11161D),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_stage == 'select_option') ...[
              const Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
                child: Text(
                  'HOW CONFIDENT ARE YOU IN THIS ANSWER?',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Row(
                children: _confidenceOptions.entries.map((entry) {
                  final color = _getConfidenceColor(entry.key);
                  final isSelected = _tempConfidenceLevel == entry.key;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => _selectConfidence(entry.key),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.25)
                                : const Color(
                                    0xFF161C24,
                                  ).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.white.withValues(alpha: 0.05),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color:
                      (_tempSelectedAnswerIndex != null &&
                          _tempConfidenceLevel != null)
                      ? const Color(0xFFF27121)
                      : const Color(0xFF161C24).withValues(alpha: 0.4),
                  boxShadow:
                      (_tempSelectedAnswerIndex != null &&
                          _tempConfidenceLevel != null)
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFF27121,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                  border:
                      (_tempSelectedAnswerIndex != null &&
                          _tempConfidenceLevel != null)
                      ? null
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1.5,
                        ),
                ),
                child: ElevatedButton(
                  onPressed: _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Submit Answer',
                        style: TextStyle(
                          color:
                              (_tempSelectedAnswerIndex != null &&
                                  _tempConfidenceLevel != null)
                              ? Colors.white
                              : Colors.white30,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.send_rounded,
                        size: 16,
                        color:
                            (_tempSelectedAnswerIndex != null &&
                                _tempConfidenceLevel != null)
                            ? Colors.white
                            : Colors.white30,
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_stage == 'explain_and_followup') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _followUpController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onSubmitted: (_) => _sendFollowUp(),
                      decoration: InputDecoration(
                        hintText: 'Ask a follow-up question...',
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: const Color(0xFFF27121),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendFollowUp,
                    icon: const Icon(Icons.send_rounded),
                    color: const Color(0xFFF27121),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFF27121),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF27121).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _tutorialContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Contnue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    if (_isLoading || _messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFF27121)),
            SizedBox(height: 16),
            Text(
              'Connecting to tutor session...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final activeQuestion = _questions.isNotEmpty
        ? _questions[_currentIndex]
        : null;

    return Column(
      children: [
        // Premium custom AppBar header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tutorial.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CommonWidgets.buildProgressColumn(
                          widget.tutorial.progress,
                          Efficiency.beginner,
                        ),
                        const SizedBox(width: 24),
                        CommonWidgets.buildProgressColumn(
                          widget.tutorial.progress,
                          Efficiency.competent,
                        ),
                        const SizedBox(width: 24),
                        CommonWidgets.buildProgressColumn(
                          widget.tutorial.progress,
                          Efficiency.expert,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chat Conversation Log Area
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(24.0),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isLast = index == _messages.length - 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(children: _buildChatMessageItem(message, isLast)),
              );
            },
          ),
        ),

        // Bottom input/selection panel
        _buildBottomPanel(activeQuestion),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F13), Color(0xFF141923), Color(0xFF0F1319)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              width: min(680, size.width),
              color: Colors.white.withValues(alpha: 0.02),
              child: Stack(
                children: [
                  // Glowing background patterns
                  Positioned(
                    top: -size.height * 0.1,
                    right: -size.width * 0.2,
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF27121).withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -size.height * 0.1,
                    left: -size.width * 0.2,
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF27121).withValues(alpha: 0.06),
                      ),
                    ),
                  ),

                  // Main content layout
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 680 : double.infinity,
                      ),
                      child: _isFinished
                          ? _buildResultsView()
                          : _buildQuizView(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final scorePct = _calculateScorePercentage();
    final correctCount = _calculateCorrectCount();
    final avgConf = _calculateAverageConfidence();
    final confText = _getConfidenceTextFromScore(avgConf);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Header Title
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF38EF7D).withValues(alpha: 0.1),
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFF38EF7D),
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Rehearsal Completed!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                widget.tutorial.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Score and Confidence Overview Cards
            Row(
              children: [
                // Score Gauge Card
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161C24).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'ACCURACY',
                              style: TextStyle(
                                color: Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: scorePct,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.04,
                                    ),
                                    color: scorePct > 0.7
                                        ? const Color(0xFF38EF7D)
                                        : scorePct > 0.4
                                        ? const Color(0xFFFF9F43)
                                        : const Color(0xFFF50057),
                                  ),
                                ),
                                Text(
                                  '$correctCount / ${_questions.length}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(scorePct * 100).toInt()}% Correct',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: scorePct > 0.7
                                    ? const Color(0xFF38EF7D)
                                    : scorePct > 0.4
                                    ? const Color(0xFFFF9F43)
                                    : const Color(0xFFF50057),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Average Confidence Card
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161C24).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'CONFIDENCE',
                              style: TextStyle(
                                color: Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: avgConf,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.04,
                                    ),
                                    color: const Color(0xFF38B6FF),
                                  ),
                                ),
                                Text(
                                  '${(avgConf * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              confText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38B6FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Detailed Breakdown header
            const Text(
              'QUESTION BREAKDOWN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white38,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Questions list review
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                final userSelect = _selectedAnswers[index];
                final isCorrect = userSelect == question.correctAnswerIndex;
                final confidence = _confidenceLevels[index] ?? 'No Idea';
                final confidenceColor = _getConfidenceColor(confidence);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161C24).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question Number & Status icon
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCorrect
                                    ? const Color(
                                        0xFF38EF7D,
                                      ).withValues(alpha: 0.15)
                                    : const Color(
                                        0xFFF50057,
                                      ).withValues(alpha: 0.15),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isCorrect
                                    ? Icons.check_rounded
                                    : Icons.close_rounded,
                                color: isCorrect
                                    ? const Color(0xFF38EF7D)
                                    : const Color(0xFFF50057),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Question ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white38,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              question.difficulty == 'Beginner'
                                              ? const Color(
                                                  0xFF38EF7D,
                                                ).withValues(alpha: 0.15)
                                              : question.difficulty ==
                                                    'Intermediate'
                                              ? const Color(
                                                  0xFFFF9F43,
                                                ).withValues(alpha: 0.15)
                                              : const Color(
                                                  0xFFF50057,
                                                ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          question.difficulty.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                question.difficulty ==
                                                    'Beginner'
                                                ? const Color(0xFF38EF7D)
                                                : question.difficulty ==
                                                      'Intermediate'
                                                ? const Color(0xFFFF9F43)
                                                : const Color(0xFFF50057),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    question.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        // Answer selections details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Answer',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white38,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userSelect != null
                                        ? question.options[userSelect]
                                        : 'None',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect
                                          ? const Color(0xFF38EF7D)
                                          : const Color(0xFFF50057),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isCorrect) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Correct Answer',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white38,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      question.options[question
                                          .correctAnswerIndex],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF38EF7D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            // Confidence Indicator
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Confidence',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white38,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  decoration: BoxDecoration(
                                    color: confidenceColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: confidenceColor.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    confidence,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: confidenceColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Back to Dashboard / Retry Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedAnswers.clear();
                        _confidenceLevels.clear();
                        _currentIndex = 0;
                        _isFinished = false;
                        _messages.clear();
                        _tempSelectedAnswerIndex = null;
                        _tempConfidenceLevel = null;
                        _stage = 'select_option';
                        _initializeChat();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFFF27121),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Finish Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
