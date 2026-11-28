import 'package:civic_net/services/notification_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new request opens the request', () {
    expect(
      routeForNotification({'type': 'new_request', 'requestId': '12'}),
      '/request/12',
    );
  });

  test('an SOS opens the request so the helper sees it at once', () {
    expect(
      routeForNotification({'type': 'sos', 'requestId': '99'}),
      '/request/99',
    );
    expect(
      routeForNotification({'type': 'SOS', 'requestId': '99'}),
      '/request/99',
    );
  });

  test('chat messages open the conversation', () {
    expect(
      routeForNotification({'type': 'chat', 'conversationId': 'c1'}),
      '/chat-detail?id=c1',
    );
    expect(
      routeForNotification({'conversation_id': 'c2'}),
      '/chat-detail?id=c2',
    );
  });

  test('an event opens the event', () {
    expect(routeForNotification({'type': 'event', 'eventId': '5'}), '/event/5');
  });

  test('with no id or an unknown type there is nowhere to go', () {
    expect(routeForNotification({'type': 'sos'}), isNull);
    expect(routeForNotification({'type': 'mystery', 'id': '1'}), isNull);
    expect(routeForNotification({}), isNull);
  });
}
