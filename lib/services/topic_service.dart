import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:testu_cl/models/chat_message.dart';
import 'package:testu_cl/services/auth_service.dart';
import 'package:testu_cl/utils/log.dart';
import '../models/topic.dart';
import '../models/tutor_channel.dart';
import '../models/tutorial.dart';

class TopicService {
  final http.Client _client;
  final String mediaDBModuleRoot;

  TopicService({
    http.Client? client,
    this.mediaDBModuleRoot =
        'http://localhost.com:8080/site/mediadb/services/module',
  }) : _client = client ?? http.Client();

  Future<List<Topic>> fetchTopics({bool fallbackToMock = true}) async {
    final targetUrl = "$mediaDBModuleRoot/entitytopic/topics.json";
    final uri = Uri.parse(targetUrl);

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> jsonList;

        if (decoded is Map<String, dynamic>) {
          jsonList = decoded['topics'] as List<dynamic>? ?? [];
        } else {
          throw FormatException('Unexpected response format from $targetUrl');
        }

        return jsonList
            .map((item) => Topic.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to fetch topics. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      logPrint('TopicService error fetching from $targetUrl');
      rethrow;
    }
  }

  Future<List<Tutorial>> fetchTutorialsForTopic(String topicId) async {
    final targetUrl =
        "$mediaDBModuleRoot/entitytutorial/tutorials.json?entitytopic=$topicId";
    final uri = Uri.parse(targetUrl);

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> jsonList;

        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          jsonList =
              decoded['tutorials'] as List<dynamic>? ??
              decoded['data'] as List<dynamic>? ??
              [];
        } else {
          throw FormatException('Unexpected response format from $targetUrl');
        }

        return jsonList
            .map((item) => Tutorial.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to fetch tutorials. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      logPrint('TopicService error fetching tutorials from $targetUrl');
      rethrow;
    }
  }

  Future<TutorialDetail> fetchTutorialDetail(String tutorialId) async {
    final targetUrl =
        "$mediaDBModuleRoot/entitytutorial/tutorial.json?entitytutorial=$tutorialId";
    final uri = Uri.parse(targetUrl);

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return TutorialDetail.fromJson(decoded);
        } else {
          throw FormatException('Unexpected response format from $targetUrl');
        }
      } else {
        throw Exception(
          'Failed to fetch tutorial details. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      logPrint('TopicService error fetching tutorial detail from $targetUrl');

      rethrow;
    }
  }

  Future<TutorChannel?> fetchTutorChannel(
    String tutorialId, {
    bool createNew = false,
  }) async {
    String targetUrl =
        "$mediaDBModuleRoot/entitytutorial/tutorsession.json?dataid=$tutorialId";
    if (createNew) targetUrl += "&createnew=$createNew";
    final uri = Uri.parse(targetUrl);

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final channel = decoded['channel'];
          if (channel is Map<String, dynamic>) {
            return TutorChannel.fromJson(channel);
          }
          if (!createNew) {
            return await fetchTutorChannel(tutorialId, createNew: true);
          }
          return null;
        } else {
          throw FormatException('Unexpected response format from $targetUrl');
        }
      } else {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      logPrint('TopicService error fetching tutor channels from $targetUrl');
      rethrow;
    }
  }

  Future<List<ChatMessage>> fetchTutorHistory({
    required String channelId,
    String? fromBeforeId,
  }) async {
    final targetUrl =
        "$mediaDBModuleRoot/entitytutorial/tutorhistory.json?channel=$channelId${fromBeforeId != null ? '&fromid=$fromBeforeId' : ''}";
    final url = Uri.parse(targetUrl);

    logPrint("fetchTutorHistory $targetUrl");

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final history = decoded['messages'] as dynamic;
          final List answers = decoded['answers'] is List
              ? decoded['answers']
              : [];
          final List<ChatMessage> messages = [];
          if (history is List) {
            for (final item in history) {
              try {
                final message = ChatMessage.fromJson(item);
                if (message.messageType!.isQuestion) {
                  final answer = answers.isEmpty
                      ? null
                      : answers.firstWhere(
                          (a) =>
                              a['questionid'] ==
                              message.rawJson['question']['id'],
                        );
                  if (answer != null) {
                    final letterASCII = answer['selectedoption']
                        ?.toString()
                        .codeUnitAt(7);
                    if (letterASCII != null) {
                      message.rawJson['selected_option_index'] =
                          letterASCII - 97;
                    }
                    if (answer['confidence'] != null) {
                      message.rawJson['confidence'] = answer['confidence'];
                    }
                    message.interactive = false;
                  } else {
                    messages.add(message);
                    break;
                  }
                }
                messages.add(message);
              } catch (e) {
                logPrint(
                  'TopicService error fetching tutor history from $targetUrl',
                );
              }
            }
          }
          return messages;
        } else {
          throw FormatException('Unexpected response format from $targetUrl');
        }
      } else {
        throw Exception(
          'Failed to fetch tutor history. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      logPrint('TopicService error fetching tutor history from $targetUrl');
      rethrow;
    }
  }

  Future<void> startTutorial({
    required String tutorialId,
    required String channel,
  }) async {
    final targetUrl = "$mediaDBModuleRoot/entitytutorial/start.json";
    final uri = Uri.parse(targetUrl);

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.post(
        uri,
        body:
            'context_tutorialid=$tutorialId&functionname=chat_tutor_welcome&currentscenario=chat_tutor&channel=$channel',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      logPrint('TopicService error fetching tutor channels from $targetUrl');
      rethrow;
    }
  }

  Future<void> continueTutorial({
    required String tutorialId,
    String? channel,
    String? sectionId,
    String? componentId,
  }) async {
    final targetUrl = "$mediaDBModuleRoot/entitytutorial/start.json";
    final uri = Uri.parse(targetUrl);

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;

      String body =
          'functionname=chat_tutor_continue&currentscenario=chat_tutor&channel=$channel';
      body += '&context_tutorialid=$tutorialId';
      if (channel != null) body += '&context_channelid=$channel';
      if (sectionId != null) body += '&context_sectionid=$sectionId';
      if (componentId != null) body += '&context_componentid=$componentId';

      logPrint("Continuing with: $body");

      final response = await _client.post(
        uri,
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        logPrint('TopicService error fetching tutor channels from $targetUrl');
      }
      rethrow;
    }
  }

  Future<void> submitAnswer({
    required String channel,
    required String questionId,
    required String selectedOption,
    required String confidence,
    required String sectionId,
    required String componentId,
  }) async {
    final targetUrl = "$mediaDBModuleRoot/entitytutorial/start.json";
    final uri = Uri.parse(targetUrl);
    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;

      String body =
          'currentscenario=chat_tutor&functionname=chat_tutor_answer&channel=$channel';
      body += '&context_channelid=$channel';
      body += '&context_questionid=$questionId';
      body += '&context_selectedoption=$selectedOption';
      body += '&context_confidence=$confidence';
      body += '&context_sectionid=$sectionId';
      body += '&context_componentid=$componentId';

      final response = await _client.post(
        uri,
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      logPrint('TopicService error fetching tutor channels from $targetUrl');

      rethrow;
    }
  }
}
