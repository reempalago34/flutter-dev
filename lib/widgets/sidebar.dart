import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/navigation.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import 'avatar.dart';
import 'download_menu_button.dart';

/// Sidebar lateral para desktop (>= 800px) — equivalente al `Sidebar` de Next.js.
///
/// Secciones:
/// 1. Menú Principal (kMainNav)
/// 2. Crear contenido (solo logueados no invitados)
/// 3. Ayuda (ocultable via preferencias)
/// 4. Perfil usuario + botón configuración
class DevSidebar extends StatefulWidget {
  final ViewId currentView;
  final ValueChanged<ViewId> onViewChanged;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onCreatePost;
  final VoidCallback? onCreateBeta;
  final VoidCallback? onCreatePoll;
  final VoidCallback? onStartTour;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenStore;
  final VoidCallback? onOpenReports;
  final VoidCallback? onShowAbout;
  final VoidCallback? onDownloadTap;

  /// Abre el perfil del usuario en sesión (tarjeta del pie del sidebar).
  final VoidCallback? onProfileTap;

  final GlobalKey? helpTourKey;

  const DevSidebar({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    this.helpTourKey,
    this.onSettingsTap,
    this.onCreatePost,
    this.onCreateBeta,
    this.onCreatePoll,
    this.onStartTour,
    this.onLogout,
    this.onOpenStore,
    this.onOpenReports,
    this.onShowAbout,
    this.onDownloadTap,
    this.onProfileTap,
  });

  @override
  State<DevSidebar> createState() => _DevSidebarState();
}

class _DevSidebarState extends State<DevSidebar> {
  bool _sidebarCompact = false;
  bool _hideHelp = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final isAuthed = auth.isAuthenticated;
        final isGuest = user?.isGuest ?? false;
        final canCreate = isAuthed && !isGuest;

        return Container(
          width: _sidebarCompact ? 64 : 224,
          decoration: const BoxDecoration(
            color: DevColors.surface,
            border: Border(
              right: BorderSide(color: DevColors.border, width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header con logo y botón compactar
              _buildHeader(),
              const SizedBox(height: 8),

              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: _sidebarCompact ? 8 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección 1: Menú Principal
                      if (!_sidebarCompact)
                        _buildSectionTitle('Menú principal'),
                      _buildMainNav(canCreate),

                      const SizedBox(height: 12),
                      if (!_sidebarCompact) _buildSectionTitle('Descargas'),
                      DownloadMenuButton(
                        compact: _sidebarCompact,
                        onTap: widget.onDownloadTap ?? () {},
                      ),

                      // Sección 2: Crear contenido
                      if (canCreate) ...[
                        const SizedBox(height: 16),
                        if (!_sidebarCompact)
                          _buildSectionTitle('Crear contenido'),
                        _buildCreateItems(),
                      ],

                      // Sección 3: Ayuda
                      if (!_hideHelp) ...[
                        const SizedBox(height: 16),
                        if (!_sidebarCompact) _buildSectionTitle('Ayuda'),
                        _buildHelpItems(),
                      ],

                      // Espacio para empujar el perfil al fondo
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Perfil de usuario al final
              if (user != null) _buildUserCard(user, canCreate),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _sidebarCompact ? 8 : 12,
        vertical: 8,
      ),
      child: Row(
        children: [
          if (!_sidebarCompact) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F0FF), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: DevColors.gold35),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                size: 18,
                color: DevColors.cream,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'DevPlay',
              style: DevTheme.display(size: 16).copyWith(letterSpacing: -0.5),
            ),
          ] else ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F0FF), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: DevColors.gold35),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                size: 18,
                color: DevColors.cream,
              ),
            ),
          ],
          const Spacer(),
          // Botón opciones (⋯) / compactar
          PopupMenuButton<String>(
            icon: Icon(
              _sidebarCompact
                  ? Icons.chevron_right_rounded
                  : Icons.more_horiz_rounded,
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
                switch (value) {
                  case 'compact':
                    _sidebarCompact = !_sidebarCompact;
                    break;
                  case 'hide_help':
                    _hideHelp = !_hideHelp;
                    break;
                  case 'reset':
                    _sidebarCompact = false;
                    _hideHelp = false;
                    break;
                  case 'logout':
                    widget.onLogout?.call();
                    break;
                }
              });
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'compact',
                child: Row(
                  children: [
                    Icon(
                      _sidebarCompact
                          ? Icons.chevron_left_rounded
                          : Icons.compress_rounded,
                      size: 16,
                      color: DevColors.foreground,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _sidebarCompact ? 'Expandir' : 'Modo compacto',
                      style: DevTheme.body(size: 13),
                    ),
                  ],
                ),
              ),
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
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(
                      Icons.restart_alt_rounded,
                      size: 16,
                      color: DevColors.mutedFg,
                    ),
                    const SizedBox(width: 10),
                    Text('Restablecer todo', style: DevTheme.body(size: 13)),
                  ],
                ),
              ),
              if (context.read<AuthProvider>().isAuthenticated)
                const PopupMenuDivider(),
              if (context.read<AuthProvider>().isAuthenticated)
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: DevColors.destructive,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cerrar sesión',
                        style: DevTheme.body(
                          size: 13,
                          color: DevColors.destructive,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Row(
        children: [
          Container(width: 16, height: 1, color: DevColors.wine),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: DevTheme.body(
              size: 10,
              w: FontWeight.w700,
              color: DevColors.mutedFg,
            ).copyWith(letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildMainNav(bool canCreate) {
    return Column(
      children: kMainNav.map((item) {
        final active = widget.currentView == item.id;
        return _NavButton(
          item: item,
          active: active,
          compact: _sidebarCompact,
          onTap: () {
            if (item.id == ViewId.store) {
              widget.onOpenStore?.call();
            } else {
              widget.onViewChanged(item.id);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildCreateItems() {
    return Column(
      children: kCreateItems.map((item) {
        return _CreateButton(
          item: item,
          compact: _sidebarCompact,
          onTap: () {
            if (item.label == 'Subir beta') {
              widget.onCreateBeta?.call();
            } else if (item.label == 'Crear encuesta') {
              widget.onCreatePoll?.call();
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildHelpItems() {
    return Column(
      children: kHelpItems.map((item) {
        return _HelpButton(
          key: item.label == 'Tour guiado' ? widget.helpTourKey : null,
          item: item,
          compact: _sidebarCompact,
          onTap: () {
            if (item.label == 'Tour guiado') {
              widget.onStartTour?.call();
            } else if (item.label == 'Acerca de DevPlay') {
              widget.onShowAbout?.call();
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildUserCard(user, bool canCreate) {
    // La tarjeta abre el perfil del usuario en sesión. Antes no era
    // clicable y solo respondía el engranaje, que llevaba a "Acerca de".
    final avatar = UserAvatar(
      username: user.username,
      avatar: user.avatar,
      size: _sidebarCompact ? 32 : 36,
    );

    // El bloque de texto va FUERA del InkWell: un `Expanded` no puede vivir
    // dentro de un `Padding` (exige un ancestro Flex).
    final info = !_sidebarCompact
        ? Expanded(
            child: InkWell(
              onTap: widget.onProfileTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: DevTheme.body(size: 13, w: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.isGuest
                          ? 'Invitado'
                          : user.role == 'DEV'
                          ? 'Desarrollador'
                          : 'Jugador',
                      style: DevTheme.body(size: 10, color: DevColors.mutedFg),
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _sidebarCompact ? 8 : 12,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DevColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: widget.onProfileTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(padding: const EdgeInsets.all(2), child: avatar),
          ),
          if (!_sidebarCompact) ...[const SizedBox(width: 10), info],
          if (!_sidebarCompact)
            IconButton(
              icon: const Icon(
                Icons.settings_rounded,
                size: 18,
                color: DevColors.mutedFg,
              ),
              onPressed: widget.onSettingsTap,
              tooltip: 'Configuración',
            ),
        ],
      ),
    );
  }
}

/// Botón de navegación principal con gradiente en el icono.
class _NavButton extends StatelessWidget {
  final NavItem item;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.active,
    required this.compact,
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
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 8 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active
                ? DevColors.accentCyan.withValues(alpha: 0.12)
                : Colors.transparent,
            border: active
                ? Border.all(
                    color: DevColors.accentCyan.withValues(alpha: 0.75),
                    width: 1.5,
                  )
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: DevColors.accentCyan.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Icono con gradiente
              Container(
                width: compact ? 32 : 36,
                height: compact ? 32 : 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: active
                      ? item.gradient
                      : const LinearGradient(
                          colors: [DevColors.muted, DevColors.muted],
                        ),
                ),
                child: Icon(
                  item.icon,
                  size: compact ? 16 : 18,
                  color: active ? DevColors.cream : DevColors.disabled,
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: DevTheme.body(
                          size: 13,
                          w: active ? FontWeight.w700 : FontWeight.w500,
                          color: active
                              ? DevColors.accentCyan
                              : DevColors.mutedFg,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.description,
                        style: DevTheme.body(
                          size: 10,
                          color: active
                              ? DevColors.accentCyan
                              : DevColors.mutedFg,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón para "Crear" y "Biblioteca" — solo icono + label, sin descripción en compacto.
class _CreateButton extends StatelessWidget {
  final NavItem item;
  final bool compact;
  final VoidCallback onTap;

  const _CreateButton({
    required this.item,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 6 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 32 : 36,
                height: compact ? 32 : 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [DevColors.muted, DevColors.muted],
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: compact ? 16 : 18,
                  color: DevColors.mutedFg,
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    item.label,
                    style: DevTheme.body(size: 13, w: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Accesos de ayuda con acabado cristal para que no se pierdan sobre el
/// fondo oscuro del sidebar. El tour usa una key propia para resaltarlo.
class _HelpButton extends StatelessWidget {
  final NavItem item;
  final bool compact;
  final VoidCallback onTap;

  const _HelpButton({
    super.key,
    required this.item,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTour = item.label == 'Tour guiado';
    final gradient = isTour
        ? const LinearGradient(
            colors: [Color(0xFF00F0FF), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF9AA7B4), Color(0xFF6B7A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 32 : 34,
                  height: compact ? 32 : 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: gradient,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: compact ? 16 : 18,
                    color: Colors.white,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: DevTheme.body(
                        size: 12.5,
                        w: FontWeight.w600,
                        color: DevColors.cream,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
