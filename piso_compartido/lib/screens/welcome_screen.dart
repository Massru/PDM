import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flat_provider.dart';
import 'setup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Logo ───────────────────────────────────────────────
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  size: 64,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 24),

              // ── Nombre de la app ───────────────────────────────────
              Text(
                'Piso Compartido',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Gestiona los gastos de tu piso\nde forma sencilla',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // ── Lista de pisos guardados (si hay) ──────────────────
              Consumer<FlatProvider>(
                builder: (context, flat, _) {
                  if (flat.flats.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pisos guardados',
                          style: theme.textTheme.titleSmall?.copyWith(
                              color: cs.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      ...flat.flats.map(
                        (f) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Icon(Icons.home,
                                  color: cs.primary, size: 20),
                            ),
                            title: Text(f.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${f.people.length} personas · ${f.billingDayLabel}'),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16),
                            onTap: () => flat.switchFlat(f.id),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              // ── Botón añadir piso ──────────────────────────────────
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SetupScreen()),
                ),
                icon: const Icon(Icons.add_home),
                label: const Text('Añadir piso'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}