import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';

class McpToolInvocationSheet extends ConsumerStatefulWidget {
  final McpServerModel server;
  final McpToolDefinition initialTool;
  final Function(McpToolDefinition tool, Map<String, dynamic> args)? onExecute;

  const McpToolInvocationSheet({
    super.key,
    required this.server,
    required this.initialTool,
    this.onExecute,
  });

  static Future<void> show(
    BuildContext context, {
    required McpServerModel server,
    required McpToolDefinition tool,
    Function(McpToolDefinition tool, Map<String, dynamic> args)? onExecute,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => McpToolInvocationSheet(
        server: server,
        initialTool: tool,
        onExecute: onExecute,
      ),
    );
  }

  @override
  ConsumerState<McpToolInvocationSheet> createState() => _McpToolInvocationSheetState();
}

class _McpToolInvocationSheetState extends ConsumerState<McpToolInvocationSheet> {
  late McpToolDefinition _selectedTool;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _jsonController = TextEditingController();
  bool _rawJsonMode = false;
  bool _isExecuting = false;
  McpToolCallResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _selectedTool = widget.initialTool;
    _initControllersForTool(_selectedTool);
  }

  void _initControllersForTool(McpToolDefinition tool) {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();

    final props = tool.properties;
    final initialMap = <String, dynamic>{};
    props.forEach((key, schema) {
      String defaultVal = '';
      if (schema is Map) {
        if (schema['default'] != null) {
          defaultVal = schema['default'].toString();
        } else if (schema['type'] == 'integer' || schema['type'] == 'number') {
          defaultVal = schema['description']?.toString().contains('10') == true ? '10' : '';
        }
      }
      _controllers[key] = TextEditingController(text: defaultVal);
      if (defaultVal.isNotEmpty) initialMap[key] = defaultVal;
    });

    const encoder = JsonEncoder.withIndent('  ');
    _jsonController.text = encoder.convert(initialMap);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _jsonController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _collectArguments() {
    if (_rawJsonMode) {
      try {
        final decoded = jsonDecode(_jsonController.text.trim());
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
      return {};
    }

    final Map<String, dynamic> args = {};
    _controllers.forEach((key, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        final propSchema = _selectedTool.properties[key];
        final type = propSchema is Map ? propSchema['type'] : null;

        if (type == 'integer' || type == 'number') {
          final numVal = num.tryParse(text);
          if (numVal != null) {
            args[key] = numVal;
          } else {
            args[key] = text;
          }
        } else if (type == 'boolean') {
          args[key] = text.toLowerCase() == 'true';
        } else {
          args[key] = text;
        }
      }
    });
    return args;
  }

  Future<void> _executeTool() async {
    final args = _collectArguments();

    setState(() {
      _isExecuting = true;
      _lastResult = null;
    });

    try {
      if (widget.onExecute != null) {
        widget.onExecute!(_selectedTool, args);
      }

      final client = ref.read(mcpClientServiceProvider);
      final result = await client.callTool(
        server: widget.server,
        toolName: _selectedTool.name,
        arguments: args,
      );

      // Also log execution into conversation state
      await ref.read(mcpConversationsProvider.notifier).executeTool(
            serverId: widget.server.id,
            toolName: _selectedTool.name,
            arguments: args,
          );

      if (mounted) {
        setState(() {
          _isExecuting = false;
          _lastResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _lastResult = McpToolCallResult(
            isSuccess: false,
            errorMessage: e.toString(),
            latencyMs: 0,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final serverColor = widget.server.color;

    return Material(
      color: surfaceColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: serverColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: serverColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTool.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Tool on ${widget.server.name}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: borderColor),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Tool Description
                if (_selectedTool.description.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      _selectedTool.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Switch tool dropdown if multiple available
                if (widget.server.tools.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SELECT TOOL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _rawJsonMode = !_rawJsonMode);
                        },
                        icon: Icon(
                          _rawJsonMode ? Icons.view_list_rounded : Icons.code_rounded,
                          size: 16,
                        ),
                        label: Text(_rawJsonMode ? 'Form Mode' : 'Raw JSON'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: serverColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<McpToolDefinition>(
                    initialValue: _selectedTool,
                    items: widget.server.tools.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (newTool) {
                      if (newTool != null) {
                        setState(() {
                          _selectedTool = newTool;
                          _lastResult = null;
                        });
                        _initControllersForTool(newTool);
                      }
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Parameters Form or Raw JSON
                Text(
                  'PARAMETERS / ARGUMENTS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                if (_rawJsonMode) ...[
                  TextField(
                    controller: _jsonController,
                    maxLines: 6,
                    style: GoogleFonts.firaCode(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '{\n  "param": "value"\n}',
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      filled: true,
                    ),
                  ),
                ] else if (_controllers.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      'No parameters required for this tool.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                      ),
                    ),
                  ),
                ] else ...[
                  ..._selectedTool.properties.entries.map((entry) {
                    final key = entry.key;
                    final schema = entry.value is Map ? entry.value as Map : {};
                    final isRequired = _selectedTool.requiredFields.contains(key);
                    final desc = schema['description']?.toString() ?? '';
                    final type = schema['type']?.toString() ?? 'string';
                    final controller = _controllers[key];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                key,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textDarkPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (isRequired) ...[
                                const SizedBox(width: 4),
                                const Text(
                                  '*',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkBg : AppColors.tagBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  type,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.textDarkMuted
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textDarkMuted
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Enter $key...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 10),

                // Execute Button
                ElevatedButton.icon(
                  onPressed: _isExecuting ? null : _executeTool,
                  icon: _isExecuting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(_isExecuting ? 'Executing Tool...' : 'Execute Tool (${_selectedTool.name})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: serverColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),

                const SizedBox(height: 20),

                // Execution Result Display
                if (_lastResult != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _lastResult!.isSuccess
                            ? AppColors.greenAccent.withValues(alpha: 0.4)
                            : Colors.red.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _lastResult!.isSuccess
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: _lastResult!.isSuccess
                                      ? AppColors.greenAccent
                                      : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _lastResult!.isSuccess ? 'Execution Success' : 'Execution Error',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _lastResult!.isSuccess
                                        ? AppColors.greenAccent
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_lastResult!.latencyMs}ms',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  tooltip: 'Copy output',
                                  onPressed: () {
                                    final text = _lastResult!.result != null
                                        ? jsonEncode(_lastResult!.result)
                                        : _lastResult!.errorMessage ?? '';
                                    Clipboard.setData(ClipboardData(text: text));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied result to clipboard'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _lastResult!.result != null
                              ? const JsonEncoder.withIndent('  ').convert(_lastResult!.result)
                              : _lastResult!.errorMessage ?? 'No content returned',
                          style: GoogleFonts.firaCode(
                            fontSize: 12,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
