import 'package:flutter_test/flutter_test.dart';
import 'package:eme_world/models/chat_message.dart';
import 'package:eme_world/services/chat_socket_service.dart';

void main() {
  group('ChatMessage Tests', () {
    test('ChatMessage.fromJson parses chat.js response payload correctly', () {
      final jsonMap = {
        'messageid': 'msg_123',
        'channel': 'channel_general',
        'user': 'user_456',
        'name': 'John Doe',
        'topic': 'General Chat',
        'message': 'Hello World',
        'command': 'messagereceived',
        'replytoid': 'msg_122',
        'functionname': 'onMessage',
        'nextfunctionname': 'onNextMessage',
        'createdat': 1690000000000,
      };

      final msg = ChatMessage.fromJson(jsonMap);

      expect(msg.messageId, equals('msg_123'));
      expect(msg.channel, equals('channel_general'));
      expect(msg.userId, equals('user_456'));
      expect(msg.userName, equals('John Doe'));
      expect(msg.message, equals('Hello World'));
      expect(msg.command, equals('messagereceived'));
      expect(msg.replyToId, equals('msg_122'));
      expect(
        msg.createdAt,
        equals(DateTime.fromMillisecondsSinceEpoch(1690000000000).toLocal()),
      );
      expect(msg.isMessageRemoved, isFalse);
      expect(msg.isKeepAlive, isFalse);
    });

    test('ChatMessage.fromJson handles messageremoved command', () {
      final jsonMap = {'messageid': 'msg_123', 'command': 'messageremoved'};

      final msg = ChatMessage.fromJson(jsonMap);

      expect(msg.messageId, equals('msg_123'));
      expect(msg.isMessageRemoved, isTrue);
    });

    test('ChatMessage.toJson generates expected payload', () {
      final msg = ChatMessage(
        messageId: 'msg_999',
        channel: 'channel_test',
        userId: 'user_1',
        message: 'Test message',
      );

      final jsonMap = msg.toJson();

      expect(jsonMap['messageid'], equals('msg_999'));
      expect(jsonMap['channel'], equals('channel_test'));
      expect(jsonMap['userid'], equals('user_1'));
      expect(jsonMap['message'], equals('Test message'));
    });

    test(
      'ChatMessage copyWith preserves interactive state and selectedOptionIndex',
      () {
        final msg = ChatMessage(
          messageId: 'q_1',
          messageType: MessageType.question,
          interactive: true,
        );

        final nonInteractiveMsg = msg.copyWith(
          interactive: false,
          rawJson: {'selected_option_index': 2},
        );

        expect(msg.interactive, isTrue);
        expect(nonInteractiveMsg.interactive, isFalse);
        expect(nonInteractiveMsg.selectedOptionIndex, equals(2));

        final copiedMsg = nonInteractiveMsg.copyWith(messageId: 'q_1_updated');
        expect(copiedMsg.interactive, isFalse);
        expect(copiedMsg.selectedOptionIndex, equals(2));
      },
    );

    test(
      'ChatMessage parses MessageType.asset and extracts thumbnail and url',
      () {
        final jsonMap = {
          'messageid': 'asset_001',
          'messagetype': 'asset',
          'message':
              '{"assetthumbnail": "https://example.com/thumb.png", "asseturl": "https://example.com/full.png", "caption": "Test Asset"}',
        };

        final msg = ChatMessage.fromJson(jsonMap);

        expect(msg.messageType, equals(MessageType.asset));
        expect(msg.assetThumbnail, equals('https://example.com/thumb.png'));
        expect(msg.assetUrl, equals('https://example.com/full.png'));
        expect(msg.assetCaption, equals('Test Asset'));
      },
    );

    test(
      'ChatMessage parses messagetype progress and progressupdate correctly',
      () {
        final jsonProgress = {
          'messagetype': 'progress',
          'beginnerprogress': 0.5,
          'competentprogress': 0.8,
          'expertprogress': 0.2,
        };
        final msg1 = ChatMessage.fromJson(jsonProgress);
        expect(msg1.messageType, equals(MessageType.progressupdate));

        final jsonProgressUpdate = {
          'messagetype': 'progressupdate',
          'beginnerprogress': 0.6,
        };
        final msg2 = ChatMessage.fromJson(jsonProgressUpdate);
        expect(msg2.messageType, equals(MessageType.progressupdate));
      },
    );
  });

  group('ChatSocketService Singleton & State Tests', () {
    test('ChatSocketService returns singleton instance', () {
      final s1 = ChatSocketService();
      final s2 = ChatSocketService();
      expect(identical(s1, s2), isTrue);
    });

    test('Initial connectionState is disconnected', () {
      final service = ChatSocketService();
      expect(
        service.connectionState,
        equals(SocketConnectionState.disconnected),
      );
      expect(service.isConnected, isFalse);
    });

    test('KeepAlive payload structure matches requirement', () {
      final keepAlivePayload = <String, dynamic>{
        'command': 'keepalive',
        'userid': 'test_user',
        'channel': 'test_channel',
      };
      final msg = ChatMessage.fromJson(keepAlivePayload);
      expect(msg.command, equals('keepalive'));
      expect(msg.userId, equals('test_user'));
      expect(msg.channel, equals('test_channel'));
      expect(msg.isKeepAlive, isTrue);
    });

    test('entermedia.key token parameter can be formatted in URI parameters', () {
      final queryParameters = <String, String>{
        'sessionid': '0.12345',
        'userid': 'admin',
        'channel': 'channel_1',
        'entermedia.key': 'testkey123',
      };

      final uri = Uri(
        scheme: 'ws',
        host: 'localhost.com',
        port: 8080,
        path:
            '/entermedia/services/websocket/org/entermediadb/websocket/chat/ChatConnection',
        queryParameters: queryParameters,
      );

      expect(uri.queryParameters['entermedia.key'], equals('testkey123'));
      expect(uri.queryParameters['userid'], equals('admin'));
      expect(uri.queryParameters['channel'], equals('channel_1'));
      expect(uri.host, equals('localhost.com'));
    });
  });
}
