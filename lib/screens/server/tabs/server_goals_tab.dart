import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/server_model.dart';
import '../../../theme/app_colors.dart';

class _GoalTaskItem {
  final String id;
  final String title;
  final String? assignedRole;
  final String addedBy;
  final String addedAgo;
  final bool isResolved;

  const _GoalTaskItem({
    required this.id,
    required this.title,
    this.assignedRole,
    required this.addedBy,
    required this.addedAgo,
    this.isResolved = false,
  });
}

class _GoalItem {
  final String id;
  final String title;
  final String dueDate;
  final String createdAgo;
  final String createdBy;
  final String ticketType;
  final List<_GoalTaskItem> tasks;
  final bool isResolved;

  const _GoalItem({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.createdAgo,
    required this.createdBy,
    this.ticketType = 'Chat',
    required this.tasks,
    this.isResolved = false,
  });
}

class ServerGoalsTab extends StatelessWidget {
  final ServerModel server;

  const ServerGoalsTab({super.key, required this.server});

  List<_GoalItem> _getGoalsForServer() {
    return [
      const _GoalItem(
        id: '2300',
        title: "Make sure all SSL certificates don't expire",
        dueDate: '2026-05-29',
        createdAgo: '113d:20h:33m ago',
        createdBy: 'Reana N',
        ticketType: 'Chat',
        tasks: [
          _GoalTaskItem(
            id: 't-1',
            title: "Make sure all SSL certificates don't expire",
            assignedRole: 'Java Developer - Cristobal.M',
            addedBy: 'Reana N',
            addedAgo: '113d 20h 33m ago',
          ),
        ],
      ),
      const _GoalItem(
        id: '2304',
        title: 'Launch Cross-Node Sync & P2P Data Bridge',
        dueDate: '2026-06-15',
        createdAgo: '42d:12h:10m ago',
        createdBy: 'Alex K',
        ticketType: 'Milestone',
        tasks: [
          _GoalTaskItem(
            id: 't-2',
            title: 'Deploy low-latency gossip sub-network for node syncing',
            assignedRole: 'Core Engineer - Alex.K',
            addedBy: 'Alex K',
            addedAgo: '42d 12h 10m ago',
          ),
          _GoalTaskItem(
            id: 't-3',
            title: 'Verify state consistency across backup validators',
            assignedRole: 'DevOps Lead - Jordan.P',
            addedBy: 'Jordan P',
            addedAgo: '38d 06h 15m ago',
          ),
        ],
      ),
      const _GoalItem(
        id: '2289',
        title: 'Community Governance & Tokenized Voting',
        dueDate: '2026-07-01',
        createdAgo: '18d:04h:22m ago',
        createdBy: 'Sarah T',
        ticketType: 'Proposal',
        tasks: [
          _GoalTaskItem(
            id: 't-4',
            title: 'Implement quadratic voting contracts for node grants',
            assignedRole: 'Smart Contract Dev - Sarah.T',
            addedBy: 'Sarah T',
            addedAgo: '18d 04h 22m ago',
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goals = _getGoalsForServer();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Goals',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Goals list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _buildGoalCard(context, goal, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, _GoalItem goal, bool isDark) {
    // Card styling matching the mockup:
    // Warm light-yellow tint container with amber border
    final cardBg = isDark ? const Color(0xFF262014) : const Color(0xFFFFFDE8);
    final cardBorder = isDark
        ? const Color(0xFF854D0E)
        : const Color(0xFFFDE68A);
    final dividerColor = isDark
        ? const Color(0xFF3D321D)
        : const Color(0xFFFDE68A);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Due Date Badge & Title Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Due Date Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Due on: ${goal.dueDate}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),

                // Goal Title & Actions Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '#${goal.id} ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            TextSpan(
                              text: goal.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Icons (Edit & Delete)
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Edit Goal #${goal.id}')),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.drive_file_rename_outline_rounded,
                          size: 19,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Delete Goal #${goal.id}')),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider between header and subtasks
          Divider(color: dividerColor, height: 1, thickness: 1),

          // Middle Section: Task Card(s)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: goal.tasks
                  .map((task) => _buildSubtaskItem(context, task, isDark))
                  .toList(),
            ),
          ),

          // Divider above footer
          Divider(color: dividerColor, height: 1, thickness: 1),

          // Bottom Section: Goal Footer Actions & Metadata
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Actions Row: Add Task & Resolve Goal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // + Add Task Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Add Task to Goal #${goal.id}'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Add Task',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Resolve Goal Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Goal #${goal.id} Resolved!'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DD4BF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Resolve Goal',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info Row: Created Info & Ticket Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Created Date & Author
                    Flexible(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Created ${goal.createdAgo} by ',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            TextSpan(
                              text: goal.createdBy,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Ticket Type Badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ticket Type: ',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF475569),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            goal.ticketType,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(
    BuildContext context,
    _GoalTaskItem task,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtask Title
          Text(
            task.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          // Role / Assignee Pill
          if (task.assignedRole != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.assignedRole!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.add,
                    size: 15,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF334155),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Subtask Footer: Added info and Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Added by info
              Flexible(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Added by ',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569),
                        ),
                      ),
                      TextSpan(
                        text: '${task.addedBy} ',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      TextSpan(
                        text: '${task.addedAgo} ',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      TextSpan(
                        text: '(edit)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Action Buttons: Assign Role & Resolve
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Assign Role Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Assign role for "${task.title}"'),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Assign Role',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Resolve Task Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Task resolved!')),
                        );
                      },
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF86EFAC),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 13,
                              color: Color(0xFF14532D),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Resolve',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF14532D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
