import 'dart:async';

import 'package:chat_app/app/backend_app.dart';
import 'package:chat_app/app/backend_app_services.dart';
import 'package:chat_app/core/preferences/app_preferences.dart';
import 'package:chat_app/core/presentation/chat_ui.dart';
import 'package:chat_app/features/auth/domain/entities/auth_user.dart';
import 'package:chat_app/features/auth/domain/repositories/backend_account_repository.dart';
import 'package:chat_app/features/conversations/data/repositories/api_conversations_repository.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/presentation/pages/chats_page.dart';
import 'package:chat_app/features/conversations/presentation/pages/conversation_page.dart';
import 'package:chat_app/features/users/domain/users_repository.dart';
import 'package:chat_app/features/users/presentation/pages/people_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/conversation_fakes.dart';

class AccountFake implements BackendAccountRepository {
  final changes = StreamController<AuthUser?>.broadcast(sync: true);
  AuthUser? user;
  @override
  AuthUser? get currentUser => user;
  @override
  Stream<AuthUser?> watchAuthState() => changes.stream;
  @override
  Future<void> initialize() async {
    changes.add(user);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    user = AuthUser(id: 'alice', email: email);
    changes.add(user);
  }

  @override
  Future<void> register({required String email, required String password}) =>
      login(email: email, password: password);
  @override
  Future<void> logout() async {
    user = null;
    changes.add(null);
  }
}

class UsersFake implements UsersRepository {
  UserProfile me = const UserProfile(
    id: 'alice',
    displayName: 'Alice',
    username: 'alice',
  );
  final searchGates = <String, Completer<CursorPage<UserProfile>>>{};
  @override
  Future<UserProfile> getMe() async => me;
  @override
  Future<UserProfile> getProfile(String userId) async =>
      UserProfile(id: userId, displayName: 'Bob', username: 'bob');
  @override
  Future<UserProfile> updateMe({
    required String username,
    required String displayName,
    required String bio,
  }) async => me = UserProfile(
    id: 'alice',
    username: username,
    displayName: displayName,
    bio: bio,
  );
  @override
  Future<CursorPage<UserProfile>> search(
    String query, {
    String? cursor,
  }) async =>
      searchGates[query]?.future ??
      const CursorPage(
        items: [UserProfile(id: 'bob', displayName: 'Bob', username: 'bob')],
        hasMore: false,
      );
}

ConversationMessage incoming(String id, {int created = 0}) =>
    ConversationMessage(
      id: id,
      clientMessageId: id,
      conversationId: 'chat',
      senderId: 'bob',
      createdAt: time(created),
      text: 'Hello $id',
    );
void main() {
  late FakeRest rest;
  late FakeRealtime socket;
  late ApiConversationsRepository repo;
  late UsersFake users;
  setUp(() {
    rest = FakeRest();
    socket = FakeRealtime();
    repo = ApiConversationsRepository(rest, socket);
    users = UsersFake();
  });
  tearDown(() async {
    await repo.close();
    await socket.controller.close();
  });
  testWidgets(
    'account creation completes profile; sign out clears pushed routes',
    (tester) async {
      final account = AccountFake();
      final preferencesStore = MemoryPreferencesStore();
      final preferences = AppPreferences(preferencesStore);
      users.me = const UserProfile(id: 'alice');
      await repo.start('alice');
      await tester.pumpWidget(
        BackendChatApp(
          services: BackendAppServices(
            account: account,
            conversations: repo,
            users: users,
            pause: repo.pauseRealtime,
            resume: repo.resumeRealtime,
            preferences: preferences,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(preferences.onboardingComplete, isTrue);
      await tester.tap(find.text('New here? Create account'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'alice@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Complete your profile'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display name'),
        'Alice',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'alice',
      );
      await tester.ensureVisible(find.text('Start chatting'));
      await tester.tap(find.text('Start chatting'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(preferences.themeMode, ThemeMode.dark);
      await tester.ensureVisible(find.text('Reduce motion'));
      await tester.tap(find.text('Reduce motion'));
      await tester.pumpAndSettle();
      expect(preferences.reduceMotion, isTrue);
      final restored = AppPreferences(preferencesStore);
      await restored.load();
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.reduceMotion, isTrue);
      expect(restored.onboardingComplete, isTrue);
      restored.dispose();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chat member').first);
      await tester.pumpAndSettle();
      expect(find.byType(ConversationPage), findsOneWidget);
      await account.logout();
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsWidgets);
      expect(find.byType(ConversationPage), findsNothing);
      expect(find.text('Skip'), findsNothing);
      expect(preferences.themeMode, ThemeMode.dark);
      await tester.pumpWidget(const SizedBox());
      preferences.dispose();
      await account.changes.close();
    },
  );
  testWidgets('failed outgoing stays visible and retries with the same ID', (
    tester,
  ) async {
    await repo.start('alice');
    rest.failSend = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationPage(
          repository: repo,
          users: users,
          conversation: summary(0),
          currentUserId: 'alice',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'مرحبا hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('مرحبا hello'), findsOneWidget);
    expect(find.text('Failed · Tap to retry'), findsOneWidget);
    rest.failSend = false;
    await tester.tap(find.text('Failed · Tap to retry'));
    await tester.pumpAndSettle();
    expect(rest.sentIds.toSet().length, 1);
    expect(find.text('مرحبا hello'), findsOneWidget);
    expect(find.text('Failed · Tap to retry'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'newest message is at the bottom; older offscreen messages are not rendered',
    (tester) async {
      rest.history.addAll(
        List.generate(40, (i) => incoming('m$i', created: i)),
      );
      await repo.start('alice');
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationPage(
            repository: repo,
            users: users,
            conversation: summary(40),
            currentUserId: 'alice',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello m39'), findsOneWidget);
      expect(find.text('Hello m0'), findsNothing);
      expect(
        repo.currentState.readPointers
            .where((p) => p.userId == 'alice')
            .single
            .lastReadMessageId,
        'm39',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('old search responses cannot overwrite a newer query', (
    tester,
  ) async {
    final old = Completer<CursorPage<UserProfile>>();
    users.searchGates['old'] = old;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeoplePage(
            users: users,
            conversations: repo,
            currentUserId: 'alice',
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'bob');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    old.complete(
      const CursorPage(
        items: [UserProfile(id: 'old', displayName: 'Old result')],
        hasMore: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Old result'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('reply, edit and confirmed delete use the message actions', (
    tester,
  ) async {
    rest.history.add(message('mine', text: 'My original'));
    await repo.start('alice');
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationPage(
          repository: repo,
          users: users,
          conversation: summary(0),
          currentUserId: 'alice',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.text('My original'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(find.text('Replying'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'A reply');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(rest.lastReply, 'mine');
    await tester.longPress(find.text('My original'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My updated');
    await tester.pump();
    await tester.tap(find.byTooltip('Save edit'));
    await tester.pumpAndSettle();
    expect(find.text('My updated'), findsOneWidget);
    expect(find.text('Editing message'), findsNothing);
    await tester.longPress(find.text('My updated'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Message deleted'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'covered and background chat routes do not mark new messages as read',
    (tester) async {
      rest.history.add(incoming('first'));
      await repo.start('alice');
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationPage(
            repository: repo,
            users: users,
            conversation: summary(0),
            currentUserId: 'alice',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initialReads = rest.readIds.length;
      await tester.tap(find.text('Chat member'));
      await tester.pumpAndSettle();
      final next = incoming('next', created: 1);
      rest.history.add(next);
      socket.emit(changed('next-event', next));
      await tester.pumpAndSettle();
      expect(rest.readIds.length, initialReads);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(rest.readIds.last, 'next');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final background = incoming('background', created: 2);
      rest.history.add(background);
      socket.emit(changed('background-event', background));
      await tester.pumpAndSettle();
      expect(rest.readIds.last, 'next');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(rest.readIds.last, 'background');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'small landscape and scaled RTL layouts can scroll without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await repo.start('alice');
      Widget scaled(Widget child) => MaterialApp(
        theme: backendTheme(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(568, 320),
            textScaler: TextScaler.linear(2),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: child),
          ),
        ),
      );
      await tester.pumpWidget(
        scaled(
          ChatsPage(
            repository: repo,
            users: users,
            currentUserId: 'alice',
            onFindPeople: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        scaled(
          PeoplePage(users: users, conversations: repo, currentUserId: 'alice'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(messageDirection('مرحبا hello'), TextDirection.rtl);
      expect(messageDirection('Hello مرحبا'), TextDirection.ltr);
      expect(messageLength('😀' * 4000), 4000);
      expect(messageLength('♥️'), 1);
    },
  );
  test(
    'read receipts compare canonical message position, not publication time',
    () {
      final m = message('m', created: 10);
      expect(
        covers(
          ReadPointer(
            conversationId: 'chat',
            userId: 'bob',
            lastReadMessageId: 'old',
            lastReadAt: time(100),
            lastReadMessageCreatedAt: time(1),
          ),
          m,
          [m],
        ),
        isFalse,
      );
    },
  );
}
