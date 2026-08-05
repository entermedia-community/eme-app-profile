import 'package:flutter/material.dart';

class LanguageHelper {
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>(
    'English',
  );

  static String get currentLanguage => languageNotifier.value;

  static set currentLanguage(String lang) {
    languageNotifier.value = lang;
  }

  static String translate(String key, {Map<String, String>? placeholders}) {
    final translations = {
      'English': {
        'catalog_dashboard': 'Catalog / Dashboard',
        'profile': 'PROFILE',
        'overall_progress': 'Overall Progress',
        'overall_performance': 'Overall Performance',
        'topics': 'TOPICS',
        'workspace': 'WORKSPACE',
        'language': 'LANGUAGE',
        'logout': 'LOGOUT',
        'powered_by': 'Powered by eMe.world',
        'notifications': 'Notifications',
        'new_tutorials': '3 New',
        'level': 'Level 10',
        'avg_suffix': 'Avg',
        'new_tutorial_title': 'New Tutorial Available',
        'new_tutorial_body': 'Mathematical Competence 2 has been unlocked.',
        'achievement_title': 'Achievement Unlocked',
        'achievement_body': 'You completed 3 subject diagnostic tests.',
        'time_5m': '5m ago',
        'time_2h': '2h ago',
        'tutorials_count': '{count} tutorials',
        'days_to_go': 'days to go',
        'efficiency': 'efficiency',
        'moderate': 'Moderate',
        'last_updated': 'Last updated: {date}',
        'tutorials': 'Tutorials',
        'total_tutorials': 'TOTAL TUTORIALS',
        'active_tutorials': '{count} Active Tutorials',
        'tests_performance': 'TESTS PERFORMANCE',
        'average_score': '{progress}% Average Score',
        'overall_topic_progress': 'Overall Topic Progress',
        'finished': '{percent}% Finished',
        'beginner': 'Beginner',
        'competent': 'Competent',
        'expert': 'Expert',
        'topics_you_excel_at': 'Topics you excel at',
        'average_rank': 'Average Rank',
        'next_rank_up': 'Average Score',
        'improve': 'Improve',
        'refresh': 'Refresh',
        'last_reviewed': 'Last reviewed {d} days ago',
        'confidence': 'Confidence',
        'privacy_policy': 'Privacy Policy',
        'app_compliance': 'Privacy Policy & Compliance',
        'data_consent_title': 'Data Collection Disclosure & Consent',
        'data_consent_body':
            'We value your privacy. We collect account details (email, name), chat interactions, and learning progress to provide personalized AI tutoring. All data is transmitted securely over HTTPS and stored safely. We do not sell your personal data.',
        'accept_consent': 'Accept & Continue',
        'decline_consent': 'Decline Non-Essential Data',
        'delete_account': 'Delete Account',
        'delete_account_confirm':
            'Are you sure you want to delete your account? This action is permanent and will erase your credentials, history, and profile data.',
        'delete_data': 'Delete Collected Data',
        'delete_data_confirm':
            'Are you sure you want to delete all collected learning and chat data? This cannot be undone.',
        'ai_generated': 'AI Generated',
        'report_ai': 'Report AI Response',
        'report_ai_success':
            'Thank you! Your report has been submitted for review.',
        'ai_disclaimer_title': 'AI Assistant Disclosure',
        'ai_disclaimer_body':
            'The AI is a learning assistant designed to explain concepts and help you understand human-authored, human-reviewed questions and answers. AI is not the driving force or evaluator in this chat.',
        'cancel': 'Cancel',
        'confirm': 'Confirm',
        'reason_hallucination': 'Hallucination / Inaccurate Information',
        'reason_inappropriate': 'Inappropriate Content',
        'reason_offensive': 'Offensive Language',
        'reason_other': 'Other Issue',
      },
      'Español': {
        'catalog_dashboard': 'Catálogo / Tablero',
        'profile': 'PERFIL',
        'overall_progress': 'Progreso general',
        'overall_performance': 'Rendimiento general',
        'topics': 'TEMAS',
        'workspace': 'ESPACIO DE TRABAJO',
        'language': 'IDIOMA',
        'logout': 'CERRAR SESIÓN',
        'powered_by': 'Desarrollado por eMe.world',
        'notifications': 'Notificaciones',
        'new_tutorials': '3 Nuevas',
        'level': 'Nivel 10',
        'avg_suffix': 'Promedio',
        'new_tutorial_title': 'Nuevo Tutorial Disponible',
        'new_tutorial_body': 'Competencia Matemática 2 ha sido desbloqueada.',
        'achievement_title': 'Logro Desbloqueado',
        'achievement_body': 'Completaste 3 pruebas de diagnóstico del tema.',
        'time_5m': 'Hace 5m',
        'time_2h': 'Hace 2h',
        'tutorials_count': '{count} tutoriales',
        'days_to_go': 'días restantes',
        'efficiency': 'eficiencia',
        'moderate': 'Moderado',
        'last_updated': 'Última actualización: {date}',
        'tutorials': 'Tutoriales',
        'total_tutorials': 'TUTORIALES TOTALES',
        'active_tutorials': '{count} Tutoriales Activos',
        'tests_performance': 'RENDIMIENTO DE PRUEBAS',
        'average_score': '{progress}% Puntaje Promedio',
        'overall_topic_progress': 'Progreso General del Tema',
        'finished': '{percent}% Finalizado',
        'beginner': 'Principiante',
        'learner': 'Aprendiz',
        'expert': 'Experto',
        'topics_you_excel_at': 'Temas en los que sobresales',
        'average_rank': 'Rango Promedio',
        'next_rank_up': 'Siguiente Nivel En',
        'improve': 'Mejorar',
        'refresh': 'Refrescar',
        'last_reviewed': 'Última revisión {d} días atrás',
        'confidence': 'Confianza',
        'privacy_policy': 'Política de Privacidad',
        'app_compliance': 'Cumplimiento de Tiendas y Datos',
        'data_consent_title': 'Divulgación y Consentimiento de Datos',
        'data_consent_body':
            'Valoramos su privacidad. Recopilamos datos de la cuenta (correo, nombre), interacciones de chat y progreso de aprendizaje para ofrecer tutoría con IA personalizada. Todos los datos se transmiten de forma segura por HTTPS y se guardan con seguridad. No vendemos sus datos personales.',
        'accept_consent': 'Aceptar y Continuar',
        'decline_consent': 'Rechazar Datos No Esenciales',
        'delete_account': 'Eliminar Cuenta',
        'delete_account_confirm':
            '¿Está seguro de que desea eliminar su cuenta? Esta acción es permanente y borrará sus credenciales, historial y datos de perfil.',
        'delete_data': 'Eliminar Datos Recopilados',
        'delete_data_confirm':
            '¿Está seguro de que desea eliminar todos los datos de aprendizaje y chat recopilados? Esto no se puede deshacer.',
        'ai_generated': 'Generado por IA',
        'report_ai': 'Reportar Respuesta de IA',
        'report_ai_success':
            '¡Gracias! Su reporte ha sido enviado para revisión.',
        'ai_disclaimer_title': 'Divulgación del Asistente de IA',
        'ai_disclaimer_body':
            'La IA es un asistente de aprendizaje diseñado para explicar conceptos y ayudarle a entender preguntas y respuestas creadas y revisadas por humanos. La IA no es la fuerza motriz ni la evaluadora en este chat.',
        'cancel': 'Cancelar',
        'confirm': 'Confirmar',
        'reason_hallucination': 'Alucinación / Información Inexacta',
        'reason_inappropriate': 'Contenido Inapropiado',
        'reason_offensive': 'Lenguaje Ofensivo',
        'reason_other': 'Otro Problema',
      },
    };

    String value = translations[currentLanguage]?[key] ?? key;
    if (placeholders != null) {
      placeholders.forEach((placeholderKey, placeholderValue) {
        value = value.replaceAll('{$placeholderKey}', placeholderValue);
      });
    }
    return value;
  }
}
