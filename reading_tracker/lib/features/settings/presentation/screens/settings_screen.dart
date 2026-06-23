import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/branding/branding.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../../core/preferences/reader_profile_text_validator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(appThemeControllerProvider);
    final controller = ref.read(appThemeControllerProvider.notifier);
    final profile = ref.watch(readerProfileControllerProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.10),
                Theme.of(context).scaffoldBackgroundColor,
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              132,
            ),
            children: [
              ReadPpPageHeader(
                readerProfile: profile,
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (_) => false,
                ),
                onAddBookTap: () => Navigator.pushNamed(context, '/book/add'),
                onCalendarTap: () => Navigator.pushNamed(context, '/calendar'),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _ProfileHero(),
              const SizedBox(height: AppSpacing.lg),
              _ReaderProfileSection(
                profile: profile,
                selectedTheme: selectedTheme,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ThemePreferenceCard(
                selectedTheme: selectedTheme,
                onChanged: controller.setTheme,
              ),
              const SizedBox(height: AppSpacing.lg),
              const _PreferencesAction(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ReadPpSurface(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      borderRadius: 30,
      opacity: 0.92,
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.24),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(
              AppIcons.profile,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfil y preferencias',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Preferencias, estilo visual y detalles personales de ReadPp.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreferenceCard extends StatelessWidget {
  const _ThemePreferenceCard({
    required this.selectedTheme,
    required this.onChanged,
  });

  final ReadingTrackerTheme selectedTheme;
  final ValueChanged<ReadingTrackerTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Estilo visual',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Elige la paleta que mejor acompaña tu lectura.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final option in ReadingTrackerTheme.values) ...[
            _ThemePreviewOption(
              option: option,
              isSelected: option == selectedTheme,
              onTap: () => onChanged(option),
            ),
            if (option != ReadingTrackerTheme.values.last)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ReaderProfileSection extends ConsumerStatefulWidget {
  const _ReaderProfileSection({
    required this.profile,
    required this.selectedTheme,
  });

  final ReaderProfile profile;
  final ReadingTrackerTheme selectedTheme;

  @override
  ConsumerState<_ReaderProfileSection> createState() =>
      _ReaderProfileSectionState();
}

class _ReaderProfileSectionState extends ConsumerState<_ReaderProfileSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _customGreetingController;
  late ReaderGreetingPreference _draftGreetingPreference;
  String? _nameError;
  String? _customGreetingError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _customGreetingController = TextEditingController(
      text: widget.profile.customGreeting,
    );
    _draftGreetingPreference = widget.profile.greetingPreference;
  }

  @override
  void didUpdateWidget(covariant _ReaderProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile.name != _nameController.text) {
      _nameController.text = widget.profile.name;
    }
    if (widget.profile.customGreeting != _customGreetingController.text) {
      _customGreetingController.text = widget.profile.customGreeting;
    }
    if (widget.profile.greetingPreference != _draftGreetingPreference) {
      _draftGreetingPreference = widget.profile.greetingPreference;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customGreetingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;
    final displayName = profile.displayName.isEmpty
        ? 'Sin nombre'
        : profile.displayName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.profile, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Perfil lector',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '¿Cómo quieres que te llamemos?',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: ReaderProfileTextValidator.maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              labelText: 'Nombre',
              hintText: 'Patricia',
              prefixIcon: const Icon(AppIcons.profile),
              errorText: _nameError,
              filled: true,
              fillColor: theme.colorScheme.surface.withValues(alpha: 0.72),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.18),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('¿Cómo prefieres el saludo?', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          RadioGroup<ReaderGreetingPreference>(
            groupValue: _draftGreetingPreference,
            onChanged: (value) {
              if (value != null) {
                setState(() => _draftGreetingPreference = value);
              }
            },
            child: Column(
              children: [
                for (final preference in ReaderGreetingPreference.values) ...[
                  Material(
                    color: preference == _draftGreetingPreference
                        ? theme.colorScheme.secondary.withValues(alpha: 0.14)
                        : theme.colorScheme.surface.withValues(alpha: 0.48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: preference == _draftGreetingPreference
                            ? theme.colorScheme.primary.withValues(alpha: 0.30)
                            : theme.colorScheme.primary.withValues(alpha: 0.10),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RadioListTile<ReaderGreetingPreference>(
                      value: preference,
                      dense: true,
                      activeColor: theme.colorScheme.primary,
                      selected: preference == _draftGreetingPreference,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      title: Text(preference.label),
                    ),
                  ),
                  if (preference != ReaderGreetingPreference.values.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
          if (_draftGreetingPreference == ReaderGreetingPreference.custom) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _customGreetingController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: ReaderProfileTextValidator.maxLength,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              onChanged: (_) {
                if (_customGreetingError != null) {
                  setState(() => _customGreetingError = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Mi propio saludo',
                hintText: 'Ej. Lectora nocturna',
                prefixIcon: const Icon(AppIcons.bookmark),
                errorText: _customGreetingError,
                filled: true,
                fillColor: theme.colorScheme.surface.withValues(alpha: 0.72),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar perfil'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfileSummary(
            displayName: displayName,
            greeting: profile.fallbackGreeting,
            themeName: widget.selectedTheme.label,
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final nameValidation = ReaderProfileTextValidator.validate(
      _nameController.text,
    );
    final customGreetingValidation =
        _draftGreetingPreference == ReaderGreetingPreference.custom
        ? ReaderProfileTextValidator.validate(
            _customGreetingController.text,
            fieldLabel: 'El saludo',
          )
        : null;
    setState(() {
      _nameError = nameValidation.error;
      _customGreetingError = customGreetingValidation?.error;
    });
    if (!nameValidation.isValid || customGreetingValidation?.isValid == false) {
      return;
    }

    final controller = ref.read(readerProfileControllerProvider.notifier);
    await controller.updateName(nameValidation.value);
    await controller.updateGreetingPreference(_draftGreetingPreference);
    if (customGreetingValidation != null) {
      await controller.updateCustomGreeting(customGreetingValidation.value);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil guardado.')));
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.displayName,
    required this.greeting,
    required this.themeName,
  });

  final String displayName;
  final String greeting;
  final String themeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          _ProfileSummaryItem(
            icon: AppIcons.profile,
            label: 'Nombre',
            value: displayName,
          ),
          const Divider(height: AppSpacing.lg),
          _ProfileSummaryItem(
            icon: AppIcons.book,
            label: 'Saludo',
            value: greeting,
          ),
          const Divider(height: AppSpacing.lg),
          _ProfileSummaryItem(
            icon: Icons.palette_outlined,
            label: 'Estilo visual',
            value: themeName,
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryItem extends StatelessWidget {
  const _ProfileSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 19),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemePreviewOption extends StatelessWidget {
  const _ThemePreviewOption({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ReadingTrackerTheme option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? option.accent.withValues(alpha: 0.16)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.42,
                  ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? option.primary.withValues(alpha: 0.48)
                  : theme.colorScheme.primary.withValues(alpha: 0.12),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _ThemePreviewSwatch(option: option),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      option == ReadingTrackerTheme.burgundy
                          ? 'Editorial cálido y protagonista.'
                          : 'Calma visual para lectura pausada.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? option.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? option.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewSwatch extends StatelessWidget {
  const _ThemePreviewSwatch({required this.option});

  final ReadingTrackerTheme option;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 48,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: option.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: option.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: option.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: option.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: option.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: option.primary.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesAction extends StatelessWidget {
  const _PreferencesAction();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showComingSoon(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
            boxShadow: AppShadows.editorial(theme.colorScheme.primary),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.24),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próximamente',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Más personalización, estadísticas y novedades para lectoras.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Próximamente'),
        content: const Text(
          'Más personalización, estadísticas y novedades para lectoras.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
