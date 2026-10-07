import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';

class HelpSupportScreen extends StatefulWidget {
  final int initialTab;

  const HelpSupportScreen({super.key, this.initialTab = 0});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);

  static const _categories = [
    ('Account', Icons.person_outline_rounded),
    ('Properties', Icons.home_outlined),
    ('Verification', Icons.verified_user_outlined),
    ('Enquiries', Icons.forum_outlined),
    ('Quotes', Icons.description_outlined),
    ('Bookings', Icons.event_outlined),
    ('Payments', Icons.payment_outlined),
    ('My Home', Icons.house_outlined),
    ('Maintenance', Icons.build_outlined),
    ('Businesses', Icons.storefront_outlined),
  ];

  static const _faqs = [
    'How do I verify my identity?',
    'How do I save a property?',
    'How do I book a viewing?',
    'How do I request a quote?',
    'Where can I find my payment receipt?',
    'How do I add my home?',
  ];

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AQARATI Support'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Home'), Tab(text: 'FAQ'), Tab(text: 'Contact'), Tab(text: 'Conversation')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('How can we help?', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('Search our resources or browse support topics', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              TextField(decoration: const InputDecoration(hintText: 'Search for help', prefixIcon: Icon(Icons.search_rounded))),
              const SizedBox(height: AppSpacing.xl),
              Text('Help Categories', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 2.4,
                children: _categories
                    .map((c) => _CategoryCard(label: c.$1, icon: c.$2, onTap: () => _tabController.animateTo(1)))
                    .toList(),
              ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Common questions', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('Instant answers to our most popular support items', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              for (final q in _faqs) _FaqTile(question: q),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Need more help?', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('Get in touch directly with our support specialists', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              _ContactCard(
                icon: Icons.chat_bubble_outline_rounded,
                badge: 'Fastest response',
                title: 'Message AQARATI Support',
                subtitle: 'Chat in-app with our support agents',
                onTap: () => _tabController.animateTo(3),
              ),
              const SizedBox(height: AppSpacing.md),
              _ContactCard(
                icon: Icons.flag_outlined,
                badge: 'Tech team',
                title: 'Report a problem',
                subtitle: 'Submit technical bugs and app crashes',
                onTap: () => _openReportSheet(context),
              ),
              const SizedBox(height: AppSpacing.md),
              _ContactCard(
                icon: Icons.edit_outlined,
                badge: null,
                title: 'Send feedback',
                subtitle: 'Tell us how we can improve',
                onTap: () {},
              ),
            ],
          ),
          const _ConversationTab(),
        ],
      ),
    );
  }

  void _openReportSheet(BuildContext context) {
    String? category;
    String? feature;
    final description = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report a problem', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'What happened?'),
                items: const ['App crash', 'Payment issue', 'Verification issue', 'Listing issue', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setSheetState(() => category = v),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: feature,
                decoration: const InputDecoration(labelText: 'Which part of AQARATI?'),
                items: const ['Search', 'Property Detail', 'Verification', 'Payments', 'Messages', 'My Home']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setSheetState(() => feature = v),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Provide details about the issue...'),
              ),
              const SizedBox(height: AppSpacing.lg),
              AqaratiButton(
                label: 'Send report',
                fullWidth: true,
                onPressed: category == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Report submitted — tracking ID #AQ-7489')),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTab extends StatefulWidget {
  const _ConversationTab();

  @override
  State<_ConversationTab> createState() => _ConversationTabState();
}

class _ConversationTabState extends State<_ConversationTab> {
  final List<(String, bool)> _messages = [
    ('Assalamu Alaikum! Welcome to AQARATI. I\'m Hamed. How can I help you today?', false),
    ('Alaykum Assalam. I\'m trying to book a viewing for a villa in Al Mouj, but the booking link displays an error.', true),
    ('I can check that for you right away. Could you please share the Property ID or listing reference?', false),
  ];
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.sand,
          child: Row(
            children: [
              const CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 18)),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hamed Al-Balushi', style: theme.textTheme.titleSmall),
                  Text('Online · Support Agent', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.verified)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final (text, isMine) = _messages[i];
              return Align(
                alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.primary : AppColors.sand,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: isMine ? Colors.white : AppColors.ink)),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _input, decoration: const InputDecoration(hintText: 'Type your message...'))),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    final text = _input.text.trim();
                    if (text.isEmpty) return;
                    setState(() {
                      _messages.add((text, true));
                      _input.clear();
                    });
                  },
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: AppIconSize.compact),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;

  const _FaqTile({required this.question});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.question, style: theme.textTheme.titleSmall)),
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.mist),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'To complete this action, open the relevant section from your Profile and follow the guided steps. If you get stuck, message our support team directly.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({required this.icon, required this.badge, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(AppRadius.sm)),
                      child: Text(badge!, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.secondary)),
                    ),
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.mist),
          ],
        ),
      ),
    );
  }
}
