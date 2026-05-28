class NotificationModel {
  final int idNotificacion;
  final int? idUsuario;
  final String? rfcEmpresa;
  final String titulo;
  final String mensaje;
  final String tipo;
  final String destinatarioTipo;
  final int leido;
  final String fechaCreacion;

  NotificationModel({
    required this.idNotificacion,
    this.idUsuario,
    this.rfcEmpresa,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.destinatarioTipo,
    required this.leido,
    required this.fechaCreacion,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      idNotificacion: json['id_notificacion'] is int
          ? json['id_notificacion']
          : int.tryParse(json['id_notificacion'].toString()) ?? 0,
      idUsuario: json['id_usuario'] != null
          ? (json['id_usuario'] is int
              ? json['id_usuario']
              : int.tryParse(json['id_usuario'].toString()))
          : null,
      rfcEmpresa: json['rfc_empresa'] as String?,
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      tipo: json['tipo'] ?? 'general',
      destinatarioTipo: json['destinatario_tipo'] ?? 'usuarios',
      leido: json['leido'] is int
          ? json['leido']
          : int.tryParse(json['leido'].toString()) ?? 0,
      fechaCreacion: json['fecha_creacion'] ?? '',
    );
  }

  /// Indica si la notificación es global (Super Admin, para todos los usuarios)
  bool get isGlobal => idUsuario == null && rfcEmpresa == null;

  /// Indica si la notificación es de empresa (para usuarios con esa ruta favorita)
  bool get isFromCompany => rfcEmpresa != null;
}
