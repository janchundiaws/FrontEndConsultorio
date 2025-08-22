import 'package:flutter/material.dart';
import 'package:odontologo/services/http_service.dart';
import 'package:odontologo/services/logger_service.dart';

class ConnectionStatus extends StatefulWidget {
  final bool showText;
  final double size;
  final Color? onlineColor;
  final Color? offlineColor;

  const ConnectionStatus({
    super.key,
    this.showText = true,
    this.size = 16.0,
    this.onlineColor,
    this.offlineColor,
  });

  @override
  State<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<ConnectionStatus> {
  bool _isOnline = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startPeriodicCheck() {
    // Verificar conexión cada 30 segundos
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _checkConnection();
        _startPeriodicCheck();
      }
    });
  }

  Future<void> _checkConnection() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final isConnected = await HttpService.checkConnectivity();
      
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
          _isChecking = false;
        });

        if (!isConnected) {
          LoggerService.warning('Conexión perdida', tag: 'NETWORK');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = false;
          _isChecking = false;
        });
      }
      LoggerService.error('Error verificando conexión', tag: 'NETWORK', error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineColor = widget.onlineColor ?? Colors.green;
    final offlineColor = widget.offlineColor ?? Colors.red;

    return GestureDetector(
      onTap: _checkConnection,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador visual
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isOnline ? onlineColor : offlineColor,
              boxShadow: [
                BoxShadow(
                  color: (_isOnline ? onlineColor : offlineColor).withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: _isChecking
                ? const Center(
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Icon(
                    _isOnline ? Icons.wifi : Icons.wifi_off,
                    size: widget.size * 0.6,
                    color: Colors.white,
                  ),
          ),
          
          // Texto opcional
          if (widget.showText) ...[
            const SizedBox(width: 8),
            Text(
              _isOnline ? 'En línea' : 'Sin conexión',
              style: TextStyle(
                color: _isOnline ? onlineColor : offlineColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget de banner de conexión
class ConnectionBanner extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onRetry;

  const ConnectionBanner({
    super.key,
    required this.isOnline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin conexión a internet',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Reintentar',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Widget de estado de conexión para AppBar
class AppBarConnectionStatus extends StatelessWidget {
  const AppBarConnectionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConnectionStatus(
      showText: false,
      size: 20,
    );
  }
}

// Widget de estado de conexión para drawer
class DrawerConnectionStatus extends StatelessWidget {
  const DrawerConnectionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConnectionStatus(
      showText: true,
      size: 24,
    );
  }
} 