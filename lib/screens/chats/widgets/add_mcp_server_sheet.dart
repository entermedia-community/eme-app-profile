import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';

class AddMcpServerSheet extends ConsumerStatefulWidget {
  final McpServerModel? initialServer;

  const AddMcpServerSheet({super.key, this.initialServer});

  static Future<void> show(BuildContext context, {McpServerModel? server}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddMcpServerSheet(initialServer: server),
    );
  }

  @override
  ConsumerState<AddMcpServerSheet> createState() => _AddMcpServerSheetState();
}

class _AddMcpServerSheetState extends ConsumerState<AddMcpServerSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _descController;
  late McpTransportType _transportType;
  int _selectedColor = 0xFF6366F1;

  bool _isTesting = false;
  String? _testStatusMessage;
  bool? _testSuccess;

  final List<int> _availableColors = [
    0xFF6366F1, // Indigo
    0xFF0284C7, // Sky Blue
    0xFF10B981, // Emerald
    0xFF8B5CF6, // Purple
    0xFFF59E0B, // Amber
    0xFFEC4899, // Pink
    0xFF0D9488, // Teal
  ];

  @override
  void initState() {
    super.initState();
    final server = widget.initialServer;
    _nameController = TextEditingController(text: server?.name ?? '');
    _urlController = TextEditingController(text: server?.url ?? '');
    _apiKeyController = TextEditingController(
      text: server?.headers['Authorization']?.replaceAll('Bearer ', '') ?? '',
    );
    _descController = TextEditingController(text: server?.description ?? '');
    _transportType = server?.transportType ?? McpTransportType.sse;
    _selectedColor = server?.colorValue ?? _availableColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testStatusMessage = 'Connecting & testing MCP handshake...';
      _testSuccess = null;
    });

    final headers = <String, String>{};
    if (_apiKeyController.text.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_apiKeyController.text.trim()}';
    }

    final tempServer = McpServerModel(
      id: 'test_temp',
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Test Server',
      url: url,
      transportType: _transportType,
      headers: headers,
      description: _descController.text.trim(),
      colorValue: _selectedColor,
      createdAt: DateTime.now(),
    );

    try {
      final client = ref.read(mcpClientServiceProvider);
      final result = await client.connectAndDiscover(tempServer);

      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = result.status == McpServerStatus.connected;
          _testStatusMessage = result.status == McpServerStatus.connected
              ? 'Connected successfully! Discovered ${result.tools.length} tool(s).'
              : 'Connection failed: ${result.errorMessage ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testStatusMessage = 'Connection failed: $e';
        });
      }
    }
  }

  Future<void> _saveServer() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final desc = _descController.text.trim();

    final headers = <String, String>{};
    if (_apiKeyController.text.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_apiKeyController.text.trim()}';
    }

    final newServer = McpServerModel(
      id:
          widget.initialServer?.id ??
          'mcp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      url: url,
      transportType: _transportType,
      headers: headers,
      description: desc,
      colorValue: _selectedColor,
      createdAt: widget.initialServer?.createdAt ?? DateTime.now(),
    );

    if (widget.initialServer != null) {
      await ref.read(mcpServersProvider.notifier).updateServer(newServer);
    } else {
      await ref.read(mcpServersProvider.notifier).addServer(newServer);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialServer != null
                ? 'MCP Server "$name" updated.'
                : 'Remote MCP Server "$name" added to chat list!',
          ),
          backgroundColor: AppColors.greenAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    return Material(
      color: surfaceColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          children: [
            // Header Drag Handle
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

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(_selectedColor).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.hub_rounded,
                      color: Color(_selectedColor),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialServer != null
                              ? 'Edit Remote MCP Server'
                              : 'Add Remote MCP Server',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Model Context Protocol Client',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textDarkMuted
                                : AppColors.textMuted,
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

            const SizedBox(height: 10),
            Divider(height: 1, color: borderColor),

            // Form Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Server Name
                    Text(
                      'Server Name *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Postgres DB MCP, GitHub Tools',
                        prefixIcon: Icon(Icons.dns_rounded, size: 20),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter a server name'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Server URL
                    Text(
                      'Remote Endpoint URL *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        hintText: 'MCP Server URL',
                        prefixIcon: Icon(Icons.link_rounded, size: 20),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter endpoint URL'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Transport Type
                    Text(
                      'Transport Protocol',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<McpTransportType>(
                      initialValue: _transportType,
                      items: McpTransportType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _transportType = val);
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.swap_calls_rounded, size: 20),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // API Key / Auth Token
                    Text(
                      'Auth Token / API Key (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _apiKeyController,
                      // obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Bearer token or MCP auth key',
                        prefixIcon: Icon(Icons.key_rounded, size: 20),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Description (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText:
                            'What tools and capabilities does this server offer?',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.notes_rounded, size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Accent Color Selector
                    Text(
                      'Badge Color',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _availableColors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Color(
                                          color,
                                        ).withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Test Connection Result Banner
                    if (_testStatusMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testSuccess == true
                              ? AppColors.greenAccent.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _testSuccess == true
                                ? AppColors.greenAccent.withValues(alpha: 0.4)
                                : Colors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _testSuccess == true
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color: _testSuccess == true
                                  ? AppColors.greenAccent
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _testStatusMessage!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: _testSuccess == true
                                      ? (isDark
                                            ? Colors.greenAccent
                                            : AppColors.greenButtonText)
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Action Buttons: Test Connection & Save
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : _testConnection,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.wifi_tethering_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              _isTesting ? 'Testing...' : 'Test Connection',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Color(_selectedColor)),
                              foregroundColor: Color(_selectedColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: _saveServer,
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: Text(
                              widget.initialServer != null
                                  ? 'Save Changes'
                                  : 'Add Server',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(_selectedColor),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
