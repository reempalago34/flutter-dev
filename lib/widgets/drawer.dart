import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/navigation.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import 'avatar.dart';
import 'animations.dart';
import 'download_menu_button.dart';

/// Drawer lateral para móvil (< 800px) — equivalente al `MobileDrawer` de Next.js.
///
/// Incluye:
/// - Header con logo, avatar/perfil, botón cerrar
/// - Grid 2x2 de "Crear" (solo logueados)
/// - Navegación principal con animaciones escalonadas
/// - Sección Ayuda (ocultable)
/// - Footer con CTA para invitados
class DevDrawer extends StatefulWidget {
  final bool open;
  final VoidCallback onClose;
  final ViewId currentView;
  final ValueChanged<ViewId> onViewChanged;
  final ValueChanged<int>? onProfileTap;
  final VoidCallback? onCreatePost;
  final VoidCallback? onCreateBeta;
  final VoidCallback? onCreatePoll;
  final VoidCallback? onStartTour;
  final VoidCallback? onOpenAuth;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenStore;
  final VoidCallback? onOpenReports;
  final VoidCallback? onShowAbout;
  final VoidCallback? onDownloadTap;

  const DevDrawer({
    super.key,
    required this.open,
    required this.onClose,
    required this.currentView,
    required this.onViewChanged,
    this.onProfileTap,
    this.onCreatePost,
    this.onCreateBeta,
    this.onCreatePoll,
    this.onStartTour,
    this.onOpenAuth,
    this.onLogout,
    this.onOpenStore,
    this.onOpenReports,
    this.onShowAbout,
    this.onDownloadTap,
  });

  @override
  State<DevDrawer> createState() => _DevDrawerState();
}

class _DevDrawerState extends State<DevDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hideHelp = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.open) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DevDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      widget.open ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final isAuthed = auth.isAuthenticated;
        final isGuest = user?.isGuest ?? false;
        final canCreate = isAuthed && !isGuest;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (!_controller.isAnimating && !widget.open) {
              return const SizedBox.shrink();
            }

            final slideX =
                -MediaQuery.of(context).size.width *
                0.88 *
                (1 - _controller.value);
            final opacity = _controller.value;

            return Stack(
              children: [
                // Overlay con blur
                if (widget.open)
                  Opacity(
                    opacity: opacity * 0.6,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        color: Colors.black,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),

                // Drawer
                Transform.translate(
                  offset: Offset(slideX, 0),
                  child: Opacity(
                    opacity: opacity,
                    child: Material(
                      color: DevColors.card,
                      elevation: 24,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.88,
                        child: Column(
                          children: [
                            // Header del drawer
                            _buildHeader(user, isAuthed, isGuest),
                            // Contenido scrolleable
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Accesos rápidos — grid 2x2 (solo crear)
                                    if (canCreate) ...[
                                      _buildSectionTitle('Crear'),
                                      const SizedBox(height: 8),
                                      _buildQuickActionsGrid(canCreate),
                                      const SizedBox(height: 20),
                                    ],

                                    // Navegación principal
                                    _buildSectionTitle('Navegación'),
                                    const SizedBox(height: 8),
                                    _buildMainNav(canCreate),

                                    const SizedBox(height: 18),
                                    _buildSectionTitle('Descargas'),
                                    const SizedBox(height: 8),
                                    DownloadMenuButton(
                                      onTap: () {
                                        widget.onClose();
                                        widget.onDownloadTap?.call();
                                      },
                                    ),

                                    // Ayuda
                                    if (!_hideHelp) ...[
                                      const SizedBox(height: 20),
                                      _buildSectionTitle('Ayuda'),
                                      const SizedBox(height: 8),
                                      _buildHelpItems(),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Footer CTA para invitados
                            if (!canCreate) _buildGuestFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(user, bool isAuthed, bool isGuest) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DevColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + opciones + cerrar
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F0FF), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: DevColors.gold35),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  size: 20,
                  color: DevColors.cream,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'DevPlay',
                style: DevTheme.display(size: 18).copyWith(letterSpacing: -0.5),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: DevColors.foreground,
                ),
                color: DevColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: DevColors.border),
                ),
                onSelected: (value) {
                  setState(() {
                    if (value == 'hide_help') _hideHelp = !_hideHelp;
                  });
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'hide_help',
                    child: Row(
                      children: [
                        Icon(
                          _hideHelp
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: 16,
                          color: DevColors.foreground,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _hideHelp ? 'Mostrar ayuda' : 'Ocultar ayuda',
                          style: DevTheme.body(size: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: DevColors.foreground,
                ),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Perfil de usuario o botones auth
          if (user != null) ...[
            InkWell(
              onTap: () {
                widget.onProfileTap?.call(0);
                widget.onClose();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DevColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DevColors.border),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      username: user.username,
                      avatar: user.avatar,
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: DevTheme.body(size: 15, w: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isGuest ? 'Modo invitado' : 'Ver mi perfil',
                            style: DevTheme.body(
                              size: 11,
                              color: DevColors.mutedFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onOpenAuth?.call();
                      widget.onClose();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DevColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Entrar',
                      style: DevTheme.body(size: 13, w: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // registro
                      widget.onOpenAuth?.call();
                      widget.onClose();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DevColors.primary,
                      foregroundColor: DevColors.primaryFg,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Crear cuenta',
                      style: DevTheme.body(size: 13, w: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: DevColors.wine),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: DevTheme.body(
            size: 10,
            w: FontWeight.w700,
            color: DevColors.mutedFg,
          ).copyWith(letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(bool canCreate) {
    if (!canCreate) return const SizedBox.shrink();

    final actions = [
      (
        'Publicar',
        Icons.article_rounded,
        const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF3B82F6)]),
      ),
      (
        'Beta',
        Icons.sports_esports_rounded,
        const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
      ),
      (
        'Encuesta',
        Icons.poll_rounded,
        const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)]),
      ),
      (
        'Stream',
        Icons.videocam_rounded,
        const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF3B82F6)]),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) {
        final (label, icon, gradient) = actions[i];
        return StaggeredEntrance(
          index: i,
          delay: const Duration(milliseconds: 50),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.onClose();
                switch (label) {
                  case 'Publicar':
                    widget.onCreatePost?.call();
                    break;
                  case 'Beta':
                    widget.onCreateBeta?.call();
                    break;
                  case 'Encuesta':
                    widget.onCreatePoll?.call();
                    break;
                  case 'Stream':
                    // TODO: implementar stream
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stream - pronto')),
                    );
                    break;
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: DevColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DevColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: gradient,
                        boxShadow: [
                          BoxShadow(
                            color: gradient.colors.first.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: DevTheme.body(size: 12, w: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainNav(bool canCreate) {
    return Column(
      children: kMainNav.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final active = widget.currentView == item.id;
        return StaggeredEntrance(
          index: i,
          delay: const Duration(milliseconds: 40),
          child: _MobileNavItem(
            item: item,
            active: active,
            onTap: () {
              if (item.id == ViewId.store) {
                widget.onOpenStore?.call();
              } else {
                widget.onViewChanged(item.id);
              }
              widget.onClose();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHelpItems() {
    return Column(
      children: [
        _HelpButton(
          icon: Icons.tour_rounded,
          label: 'Tour guiado',
          gradient: const LinearGradient(
            colors: [Color(0xFF00F0FF), Color(0xFF6D28D9)],
          ),
          onTap: () {
            widget.onStartTour?.call();
            widget.onClose();
          },
        ),
        const SizedBox(height: 6),
        _HelpButton(
          icon: Icons.info_outline_rounded,
          label: 'Acerca de DevPlay',
          gradient: const LinearGradient(
            colors: [Color(0xFF8E9BA8), Color(0xFF6B7A8A)],
          ),
          onTap: () {
            widget.onShowAbout?.call();
            widget.onClose();
          },
        ),
      ],
    );
  }

  Widget _buildGuestFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DevColors.border, width: 0.5)),
      ),
      child: ElevatedButton(
        onPressed: () {
          widget.onOpenAuth?.call();
          widget.onClose();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: DevColors.primary,
          foregroundColor: DevColors.primaryFg,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Crear cuenta gratis',
          style: DevTheme.body(size: 13, w: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Item de navegación móvil (más grande y con descripción).
class _MobileNavItem extends StatelessWidget {
  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: DevColors.accentCyan.withValues(alpha: 0.05),
        splashColor: DevColors.accentCyan.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active
                ? DevColors.accentCyan.withValues(alpha: 0.12)
                : Colors.transparent,
            border: active
                ? Border.all(
                    color: DevColors.accentCyan.withValues(alpha: 0.7),
                    width: 1.5,
                  )
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: DevColors.accentCyan.withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: active
                      ? item.gradient
                      : const LinearGradient(
                          colors: [DevColors.muted, DevColors.muted],
                        ),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: active ? DevColors.cream : DevColors.disabled,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: DevTheme.body(size: 14, w: FontWeight.w700),
                    ),
                    Text(
                      item.description,
                      style: DevTheme.body(size: 11, color: DevColors.mutedFg),
                    ),
                  ],
                ),
              ),
              if (active)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: DevColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _HelpButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: gradient,
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: DevTheme.body(
                    size: 13,
                    w: FontWeight.w600,
                    color: DevColors.cream,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
