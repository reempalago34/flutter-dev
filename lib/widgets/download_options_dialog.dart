import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

const _androidDownloadUrl = 'https://app.proyecto.sbs/downloads/DevPlay.apk';
const _linuxDebDownloadUrl =
    'https://app.proyecto.sbs/downloads/DevPlay-amd64.deb';
const _linuxTarGzDownloadUrl =
    'https://app.proyecto.sbs/downloads/DevPlay-linux-x64.tar.gz';

Future<void> showDownloadOptionsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const DownloadOptionsDialog(),
  );
}

class DownloadOptionsDialog extends StatelessWidget {
  const DownloadOptionsDialog({super.key});

  Future<void> _download(BuildContext context, String url) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la descarga.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la descarga.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DevColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: DevColors.border),
      ),
      title: Text('Descargar DevPlay', style: DevTheme.display(size: 20)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Elige la versión para tu dispositivo.',
              style: DevTheme.body(size: 13, color: DevColors.mutedFg),
            ),
            const SizedBox(height: 16),
            _DownloadOption(
              icon: Icons.android_rounded,
              title: 'Android',
              description: 'Aplicación para Android · APK',
              color: const Color(0xFF3DDC84),
              onTap: () => _download(context, _androidDownloadUrl),
            ),
            const SizedBox(height: 10),
            _DownloadOption(
              icon: Icons.computer_rounded,
              title: 'Linux (.deb)',
              description: 'Instalador para Ubuntu, Debian y derivados · doble clic para instalar',
              color: DevColors.accentCyan,
              onTap: () => _download(context, _linuxDebDownloadUrl),
            ),
            const SizedBox(height: 10),
            _DownloadOption(
              icon: Icons.computer_rounded,
              title: 'Linux (.tar.gz)',
              description: 'Paquete portable · extraer y ejecutar',
              color: DevColors.accentCyan,
              onTap: () => _download(context, _linuxTarGzDownloadUrl),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cerrar', style: DevTheme.body(size: 13)),
        ),
      ],
    );
  }
}

class _DownloadOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _DownloadOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DevColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DevColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DevTheme.body(size: 14, w: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: DevTheme.body(size: 11, color: DevColors.mutedFg),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.download_rounded,
                color: DevColors.mutedFg,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
