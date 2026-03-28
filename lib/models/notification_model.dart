class NotificationModel {
  final int idNotificacion;
  final int? idUsuario;
  final String titulo;
  final String mensaje;
  final String tipo;
  final int leido;
  final String fechaCreacion;

  NotificationModel({
    required this.idNotificacion,
    this.idUsuario,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leido,
    required this.fechaCreacion,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      idNotificacion: json['id_notificacion'] is int 
          ? json['id_notificacion'] 
          : int.tryParse(json['id_notificacion'].toString()) ?? 0,
      idUsuario: json['id_usuario'] != null 
          ? (json['id_usuario'] is int ? json['id_usuario'] : int.tryParse(json['id_usuario'].toString()))
          : null,
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      tipo: json['tipo'] ?? 'general',
      leido: json['leido'] is int 
          ? json['leido'] 
          : int.tryParse(json['leido'].toString()) ?? 0,
      fechaCreacion: json['fecha_creacion'] ?? '',
    );
  }
}
