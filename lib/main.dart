import 'package:flutter/material.dart';

void main() => runApp(const RecipeHubApp());

class NomadKit {
  static const sand = Color(0xFFD4A373);
  static const ocean = Color(0xFF0891B2);
  static const forest = Color(0xFF166534);
  static const background = Color(0xFFFFFDF7);
  static const surface = Colors.white;
  static const muted = Color(0xFFF6F1E8);
  static const ink = Color(0xFF292524);
  static const secondary = Color(0xFF78716C);
  static const border = Color(0xFFE7E0D5);
  static const warning = Color(0xFFCA8A04);
  static const error = Color(0xFFDC2626);
}

class RecipeHubApp extends StatelessWidget {
  const RecipeHubApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RecipeHub',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: NomadKit.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NomadKit.sand,
        brightness: Brightness.light,
        surface: NomadKit.surface,
        error: NomadKit.error,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: NomadKit.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: NomadKit.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: NomadKit.ink,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: NomadKit.ink, height: 1.45),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: NomadKit.secondary,
          height: 1.4,
        ),
      ),
    ),
    home: const HubShell(),
  );
}

class HubShell extends StatefulWidget {
  const HubShell({super.key});
  @override
  State<HubShell> createState() => _HubShellState();
}

class _HubShellState extends State<HubShell> {
  int _index = 0;
  final _pages = const [
    LibraryPage(),
    IngredientsPage(),
    ExportHistoryPage(),
    SettingsPage(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: _pages[_index]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      backgroundColor: NomadKit.surface,
      indicatorColor: NomadKit.sand.withValues(alpha: .28),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Recipes',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Ingredients',
        ),
        NavigationDestination(
          icon: Icon(Icons.file_download_outlined),
          selectedIcon: Icon(Icons.file_download),
          label: 'Exports',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune),
          label: 'Settings',
        ),
      ],
    ),
  );
}

class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.back = false,
  });
  final String title;
  final Widget child;
  final Widget? action;
  final bool back;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: NomadKit.background,
      surfaceTintColor: Colors.transparent,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      leading: back
          ? IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            )
          : null,
      actions: action == null ? null : [action!],
    ),
    body: SafeArea(child: child),
  );
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Make every recipe easier to run.',
          style: TextStyle(
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: NomadKit.ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Your R&D kitchen, kept clear and ready to share.'),
        const SizedBox(height: 20),
        TextField(decoration: fieldDecoration('Search recipes', Icons.search)),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          children: [
            StatusChip('All recipes', selected: true),
            StatusChip('Drafts'),
            StatusChip('Approved', tone: NomadKit.forest),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            children: [
              RecipeCard(
                'Citrus Tiramisu',
                'Dessert',
                'v2 · 45 min · Updated today',
                'Draft',
                NomadKit.warning,
                () => go(context, const RecipeDetailPage()),
              ),
              RecipeCard(
                'Charred Corn Velouté',
                'Soup',
                'v5 · 35 min · Updated yesterday',
                'Approved',
                NomadKit.forest,
                () => go(context, const RecipeDetailPage(approved: true)),
              ),
              RecipeCard(
                'Miso Caramel Tart',
                'Dessert',
                'v1 · 1 hr · Waiting for review',
                'Draft',
                NomadKit.warning,
                () => go(context, const RecipeDetailPage()),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: PrimaryButton(
            'Create recipe',
            Icons.add,
            () => go(context, const RecipeEditorPage()),
          ),
        ),
      ],
    ),
  );
}

class RecipeCard extends StatelessWidget {
  const RecipeCard(
    this.name,
    this.category,
    this.meta,
    this.status,
    this.tone,
    this.onTap, {
    super.key,
  });
  final String name, category, meta, status;
  final Color tone;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: NomadKit.secondary,
                  ),
                ),
                const Spacer(),
                StatusChip(status, tone: tone),
              ],
            ),
            const SizedBox(height: 10),
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(meta),
          ],
        ),
      ),
    ),
  );
}

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key, this.approved = false});
  final bool approved;
  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'Recipe details',
    back: true,
    action: IconButton(
      tooltip: 'Edit recipe',
      onPressed: () => go(context, const RecipeEditorPage()),
      icon: const Icon(Icons.edit_outlined),
    ),
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 170,
          decoration: BoxDecoration(
            color: NomadKit.muted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.icecream_outlined,
              size: 56,
              color: NomadKit.sand,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Citrus Tiramisu',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            StatusChip(
              approved ? 'Approved' : 'Draft',
              tone: approved ? NomadKit.forest : NomadKit.warning,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('A bright, make-ahead dessert for the seasonal menu.'),
        const SizedBox(height: 22),
        const SectionTitle('At a glance'),
        const InfoGrid(),
        const SizedBox(height: 22),
        const SectionTitle('Ingredients'),
        const InfoRow('Mascarpone', '250 g'),
        const InfoRow('Ladyfingers', '200 g'),
        const InfoRow('Orange zest', '10 g'),
        const SizedBox(height: 18),
        PrimaryButton(
          approved ? 'View immutable version' : 'Review and approve',
          approved ? Icons.lock_outline : Icons.fact_check_outlined,
          () => go(context, RecipeReviewPage(approved: approved)),
        ),
      ],
    ),
  );
}

class RecipeEditorPage extends StatefulWidget {
  const RecipeEditorPage({super.key});
  @override
  State<RecipeEditorPage> createState() => _RecipeEditorPageState();
}

class _RecipeEditorPageState extends State<RecipeEditorPage> {
  final _form = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'New recipe',
    back: true,
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Start with the essentials.',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('Saved drafts stay on this device until they can sync.'),
          const SizedBox(height: 24),
          AppTextField('Recipe name', 'Citrus Tiramisu'),
          AppTextField('Category', 'Dessert'),
          AppTextField('Servings', '4', keyboard: TextInputType.number),
          const SectionTitle('Ingredients'),
          const InfoRow('Mascarpone', '250 g'),
          const InfoRow('Ladyfingers', '200 g'),
          SecondaryButton(
            'Ask AI for a suggestion',
            Icons.auto_awesome_outlined,
            () => showAiSuggestion(context),
          ),
          const SizedBox(height: 12),
          PrimaryButton('Save and continue', Icons.arrow_forward, () {
            if (_form.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft saved locally')),
              );
              Navigator.pop(context);
            }
          }),
        ],
      ),
    ),
  );
}

class IngredientsPage extends StatelessWidget {
  const IngredientsPage({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingredients',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text('Keep stock visible before a recipe is approved.'),
        const SizedBox(height: 16),
        const Row(
          children: [
            Stat('42', 'In stock', NomadKit.forest),
            SizedBox(width: 8),
            Stat('3', 'Low stock', NomadKit.warning),
            SizedBox(width: 8),
            Stat('1', 'Expired', NomadKit.error),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            children: [
              const InfoRow('Mascarpone', '3.2 kg'),
              const InfoRow(
                'Orange zest',
                '120 g · Low',
                tone: NomadKit.warning,
              ),
              const InfoRow(
                'Cocoa powder',
                '0 g · Expired',
                tone: NomadKit.error,
              ),
            ],
          ),
        ),
        PrimaryButton(
          'Add ingredient',
          Icons.add,
          () => go(context, const IngredientFormPage()),
        ),
      ],
    ),
  );
}

class IngredientFormPage extends StatelessWidget {
  const IngredientFormPage({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'Add ingredient',
    back: true,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppTextField('Ingredient name', 'Orange zest'),
        AppTextField('Quantity', '120'),
        AppTextField('Unit', 'g'),
        AppTextField(
          'Minimum stock',
          '150',
          error: 'Minimum stock should be lower than quantity.',
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          'Save ingredient',
          Icons.check,
          () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

class RecipeReviewPage extends StatelessWidget {
  const RecipeReviewPage({super.key, required this.approved});
  final bool approved;
  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'Review recipe',
    back: true,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          approved ? 'Approved version' : 'Ready to approve',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          approved
              ? 'This version is read-only for reliable service.'
              : 'Check the recipe before making this version immutable.',
        ),
        const SizedBox(height: 22),
        const CheckRow('Recipe details are complete', true),
        const CheckRow('Ingredients are available', true),
        const CheckRow('All steps have images', false),
        const CheckRow('Allergens have been reviewed', true),
        const SizedBox(height: 20),
        if (!approved)
          PrimaryButton(
            'Approve version 2',
            Icons.verified_outlined,
            () => showSuccess(context),
          ),
      ],
    ),
  );
}

class ExportHistoryPage extends StatelessWidget {
  const ExportHistoryPage({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exports',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text('Create and recover shareable recipe books.'),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            children: [
              const InfoRow(
                'October R&D collection.pdf',
                'Ready · Today 16:42',
                tone: NomadKit.forest,
              ),
              const InfoRow(
                'Autumn desserts.pdf',
                'Ready · 12 Oct',
                tone: NomadKit.forest,
              ),
              const InfoRow(
                'Weekly test recipes.pdf',
                'Failed · Retry available',
                tone: NomadKit.error,
              ),
            ],
          ),
        ),
        PrimaryButton(
          'Create PDF export',
          Icons.picture_as_pdf_outlined,
          () => go(context, const ExportSelectionPage()),
        ),
      ],
    ),
  );
}

class ExportSelectionPage extends StatefulWidget {
  const ExportSelectionPage({super.key});
  @override
  State<ExportSelectionPage> createState() => _ExportSelectionPageState();
}

class _ExportSelectionPageState extends State<ExportSelectionPage> {
  final selected = <String>{'Charred Corn Velouté', 'Citrus Tiramisu'};
  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'Select recipes',
    back: true,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Build a service-ready PDF.',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('Only approved recipes can be exported.'),
        const SizedBox(height: 18),
        ...['Charred Corn Velouté', 'Citrus Tiramisu', 'Miso Caramel Tart'].map(
          (name) => CheckboxListTile(
            value: selected.contains(name),
            title: Text(name),
            subtitle: const Text('Approved version'),
            activeColor: NomadKit.forest,
            onChanged: (v) =>
                setState(() => v! ? selected.add(name) : selected.remove(name)),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          'Preview ${selected.length} recipes',
          Icons.visibility_outlined,
          () => go(context, PdfPreviewPage(count: selected.length)),
        ),
      ],
    ),
  );
}

class PdfPreviewPage extends StatelessWidget {
  const PdfPreviewPage({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'PDF preview',
    back: true,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NomadKit.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'R&D KITCHEN',
                style: TextStyle(
                  letterSpacing: 1,
                  color: NomadKit.ocean,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Recipe Collection',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              Divider(height: 32),
              Text('01  Charred Corn Velouté'),
              SizedBox(height: 12),
              Text('02  Citrus Tiramisu'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          'Export PDF',
          Icons.file_download_outlined,
          () => showSuccess(
            context,
            message: '$count recipes exported to history',
          ),
        ),
      ],
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Settings',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      const InfoRow('Profile', 'R&D Kitchen · Linh Tran'),
      const InfoRow('Accessibility', 'Text scaling and high contrast'),
      const InfoRow(
        'Sync status',
        'Saved locally · Ready to sync',
        tone: NomadKit.ocean,
      ),
      const InfoRow('Audit log', 'Approvals and version changes'),
    ],
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, this.icon, this.onPressed, {super.key});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: NomadKit.sand,
        foregroundColor: NomadKit.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(this.label, this.icon, this.onPressed, {super.key});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: NomadKit.ocean,
        side: const BorderSide(color: NomadKit.ocean),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(
    this.label, {
    super.key,
    this.tone = NomadKit.sand,
    this.selected = false,
  });
  final String label;
  final Color tone;
  final bool selected;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(
      selected ? Icons.check_circle : Icons.circle_outlined,
      size: 16,
      color: tone,
    ),
    label: Text(label),
    side: BorderSide(color: tone),
    backgroundColor: selected ? tone.withValues(alpha: .16) : NomadKit.surface,
    labelStyle: TextStyle(color: tone, fontWeight: FontWeight.w700),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow(
    this.title,
    this.subtitle, {
    super.key,
    this.tone = NomadKit.secondary,
  });
  final String title, subtitle;
  final Color tone;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: NomadKit.surface,
      border: Border.all(color: NomadKit.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(color: tone)),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: tone),
      ],
    ),
  );
}

class AppTextField extends StatelessWidget {
  const AppTextField(
    this.label,
    this.initial, {
    super.key,
    this.error,
    this.keyboard,
  });
  final String label, initial;
  final String? error;
  final TextInputType? keyboard;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      initialValue: initial,
      keyboardType: keyboard,
      validator: (v) =>
          v == null || v.trim().isEmpty ? '$label is required' : null,
      decoration: fieldDecoration(label, null).copyWith(errorText: error),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
  );
}

class InfoGrid extends StatelessWidget {
  const InfoGrid({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Stat('6', 'Ingredients', NomadKit.ocean),
      SizedBox(width: 8),
      Stat('5', 'Steps', NomadKit.sand),
      SizedBox(width: 8),
      Stat('4', 'Servings', NomadKit.forest),
    ],
  );
}

class Stat extends StatelessWidget {
  const Stat(this.value, this.label, this.tone, {super.key});
  final String value, label;
  final Color tone;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: NomadKit.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NomadKit.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: NomadKit.secondary),
          ),
        ],
      ),
    ),
  );
}

class CheckRow extends StatelessWidget {
  const CheckRow(this.text, this.ok, {super.key});
  final String text;
  final bool ok;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      ok ? Icons.check_circle : Icons.error_outline,
      color: ok ? NomadKit.forest : NomadKit.warning,
    ),
    title: Text(text),
    subtitle: Text(ok ? 'Complete' : 'Add a step image before approval'),
  );
}

InputDecoration fieldDecoration(String label, IconData? icon) =>
    InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: NomadKit.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NomadKit.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NomadKit.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NomadKit.ocean, width: 2),
      ),
    );
void go(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
void showAiSuggestion(BuildContext context) => showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('AI suggestion'),
    content: const Text(
      'Add 20g orange zest and reduce sugar by 10g for a brighter finish.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Not now'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Apply suggestion'),
      ),
    ],
  ),
);
void showSuccess(
  BuildContext context, {
  String message = 'Version 2 is now approved and immutable.',
}) => showDialog(
  context: context,
  builder: (_) => AlertDialog(
    icon: const Icon(Icons.check_circle, color: NomadKit.forest, size: 40),
    title: const Text('Done'),
    content: Text(message),
    actions: [
      FilledButton(
        onPressed: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        child: const Text('Continue'),
      ),
    ],
  ),
);
