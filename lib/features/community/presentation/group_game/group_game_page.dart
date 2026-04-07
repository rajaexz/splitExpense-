import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../application/group_game/group_game_cubit.dart';
import '../../../../application/group_game/group_game_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/group_game_model.dart';

class GroupGamePage extends StatefulWidget {
  final String groupId;
  final String gameId;
  final String? groupName;

  const GroupGamePage({
    super.key,
    required this.groupId,
    required this.gameId,
    this.groupName,
  });

  @override
  State<GroupGamePage> createState() => _GroupGamePageState();
}

class _GroupGamePageState extends State<GroupGamePage> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  final TextEditingController _interestsController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _interestsFocus = FocusNode();
  int? _correctOptionIndex;

  @override
  void initState() {
    super.initState();
    _questionController.addListener(() => setState(() {}));
    _answerController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    _interestsController.dispose();
    _answerController.dispose();
    _interestsFocus.dispose();
    super.dispose();
  }

  Future<void> _saveInterests() async {
    try {
      await context.read<GroupGameCubit>().setInterestsForSelf(
            _interestsController.text,
          );
      if (!mounted) return;
      _interestsFocus.unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Interests saved',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.stemBackground,
      body: SafeArea(
        child: BlocConsumer<GroupGameCubit, GroupGameState>(
          listener: (context, state) {
            if (state is GroupGameError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
            if (state is GroupGameLoaded && uid != null) {
              final mine = state.game.interestsByUserId[uid] ?? '';
              // Avoid overwriting while the user is typing; sync when unfocused or empty local + server has data.
              if (!_interestsFocus.hasFocus && _interestsController.text != mine) {
                _interestsController.text = mine;
              }
            }
          },
          builder: (context, state) {
            if (state is GroupGameLoading || state is GroupGameInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.stemEmerald),
              );
            }
            if (state is GroupGameNotFound) {
              return Center(
                child: Text(
                  'Game not found',
                  style: GoogleFonts.manrope(color: AppColors.stemMutedText),
                ),
              );
            }
            if (state is GroupGameError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: GoogleFonts.manrope(color: AppColors.stemLightText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Retry',
                      onPressed: () =>
                          context.read<GroupGameCubit>().retry(),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      text: 'Back',
                      isOutlined: true,
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              );
            }
            if (state is! GroupGameLoaded) {
              return const SizedBox.shrink();
            }
            final game = state.game;
            final isHost = uid == game.hostId;
            final names = state.displayNames;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: AppColors.stemLightText),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Question game',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.stemEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: _buildBody(
                      context,
                      game: game,
                      uid: uid,
                      isHost: isHost,
                      names: names,
                      aiGenerating: state.aiGenerating,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required GroupGameModel game,
    required String? uid,
    required bool isHost,
    required Map<String, String> names,
    required bool aiGenerating,
  }) {
    final currency = game.currency;
    final amountStr = '$currency ${game.perPersonAmount.toStringAsFixed(2)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Per person: $amountStr',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.stemMutedText,
          ),
        ),
        const SizedBox(height: 16),
        if (game.status == GroupGameStatus.setup) ...[
          Text(
            isHost
                ? 'Turn on the switch for each member once they agree. Others can tap Agree on their own phone.'
                : 'Everyone agrees to the amount, then the host continues to the payment step.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.stemGreyText,
            ),
          ),
          const SizedBox(height: 12),
          ...game.memberOrder.map((id) {
            final agreed = game.amountAgreedBy[id] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    agreed ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: agreed ? AppColors.stemEmerald : AppColors.stemMutedText,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      names[id] ?? id,
                      style: GoogleFonts.manrope(
                        color: AppColors.stemLightText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isHost)
                    Switch(
                      value: agreed,
                      activeThumbColor: AppColors.stemEmerald,
                      onChanged: (v) => context
                          .read<GroupGameCubit>()
                          .hostSetMemberAmountAgreed(id, v),
                    )
                  else if (id == uid && !agreed)
                    TextButton(
                      onPressed: () =>
                          context.read<GroupGameCubit>().agreeToAmount(),
                      child: Text(
                        'Agree',
                        style: GoogleFonts.manrope(
                          color: AppColors.stemEmerald,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Your interests (for AI favorite questions)',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.stemLightText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _interestsController,
            focusNode: _interestsFocus,
            maxLines: 2,
            style: const TextStyle(color: AppColors.stemLightText),
            decoration: InputDecoration(
              hintText: 'e.g. cricket, movies, cooking',
              hintStyle: TextStyle(color: AppColors.stemMutedText.withValues(alpha: 0.7)),
              filled: true,
              fillColor: AppColors.stemInputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.stemSurface),
              ),
            ),
            onChanged: (_) {},
          ),
          const SizedBox(height: 8),
          AppButton(
            text: 'Save interests',
            height: 44,
            onPressed: _saveInterests,
          ),
          if (isHost) ...[
            const SizedBox(height: 20),
            AppButton(
              text: 'Continue to payment',
              onPressed: game.allMembersAgreed()
                  ? () => context
                      .read<GroupGameCubit>()
                      .hostProceedToAwaitingPayment()
                  : null,
            ),
          ],
        ],
        if (game.status == GroupGameStatus.awaitingPayment) ...[
          Text(
            'Mark each member as paid when their share is received.',
            style: GoogleFonts.manrope(fontSize: 13, color: AppColors.stemGreyText),
          ),
          const SizedBox(height: 12),
          ...game.memberOrder.map((id) {
            final paid = game.payments[id] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    paid ? Icons.paid : Icons.payments_outlined,
                    color: paid ? AppColors.stemEmerald : AppColors.stemMutedText,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      names[id] ?? id,
                      style: GoogleFonts.manrope(
                        color: AppColors.stemLightText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (id == uid || isHost)
                    Switch(
                      value: paid,
                      activeThumbColor: AppColors.stemEmerald,
                      onChanged: (v) {
                        if (id == uid) {
                          context.read<GroupGameCubit>().setPaid(paid: v);
                        } else if (isHost) {
                          context.read<GroupGameCubit>().hostSetMemberPaid(id, v);
                        }
                      },
                    )
                  else
                    Icon(
                      paid ? Icons.check_circle : Icons.hourglass_empty,
                      color: paid ? AppColors.stemEmerald : AppColors.stemMutedText,
                      size: 22,
                    ),
                  if (isHost && id != uid && !paid) ...[
                    TextButton(
                      onPressed: () => context
                          .read<GroupGameCubit>()
                          .sendPaymentReminderTo(id),
                      child: Text(
                        'Remind',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.stemEmerald,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<GroupGameCubit>().sendPokeTo(id),
                      child: Text(
                        'Poke',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.stemMutedText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          AppButton(
            text: 'Pay with UPI (request QR)',
            isOutlined: true,
            onPressed: () {
              context.push(
                AppRoutes.requestPaymentQr,
                extra: {
                  'amount': game.perPersonAmount,
                  'currency': game.currency,
                  'groupName': widget.groupName ?? '',
                  'groupId': widget.groupId,
                  'membersWhoOwe': game.memberOrder
                      .where((id) => game.payments[id] != true)
                      .map(
                        (id) => {
                          'userId': id,
                          'name': names[id] ?? id,
                          'amount': game.perPersonAmount,
                        },
                      )
                      .toList(),
                },
              );
            },
          ),
          if (isHost) ...[
            const SizedBox(height: 16),
            AppButton(
              text: 'Start game',
              onPressed: game.allMembersPaid()
                  ? () => context.read<GroupGameCubit>().hostStartActive()
                  : null,
            ),
          ],
        ],
        if (game.status == GroupGameStatus.active) ...[
          Text(
            'Question ${game.questionCount + 1} of 10',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.stemEmerald,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Turn: ${names[game.currentTurnUserId() ?? ''] ?? '—'}',
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: AppColors.stemLightText,
            ),
          ),
          if (game.currentTurnUserId() == uid) ...[
            Builder(builder: (context) {
              final last = game.lastQuestion();
              final needsAnswerFirst = last != null &&
                  (last['answererId']?.toString() == uid) &&
                  ((last['answerText']?.toString().trim() ?? '').isEmpty);
              return Column(
                children: [
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final last = game.lastQuestion();
              final needsAnswer = last != null &&
                  (last['answererId']?.toString() == uid) &&
                  ((last['answerText']?.toString().trim() ?? '').isEmpty);
              final askedAt = last?['askedAt'];
              DateTime? asked;
              if (askedAt is Timestamp) asked = askedAt.toDate();
              final deadline = asked?.add(const Duration(minutes: 5));
              final secondsLeft = deadline == null
                  ? 0
                  : deadline.difference(DateTime.now()).inSeconds;
              final showTimer = needsAnswer && deadline != null;
              final timeStr = () {
                final s = secondsLeft.clamp(0, 300);
                final mm = (s ~/ 60).toString().padLeft(2, '0');
                final ss = (s % 60).toString().padLeft(2, '0');
                return '$mm:$ss';
              }();

              if (!needsAnswer) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Answer the previous question first',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.stemLightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    last['text']?.toString() ?? '',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.stemMutedText,
                    ),
                  ),
                  if (last['options'] is List) ...[
                    const SizedBox(height: 8),
                    ...(last['options'] as List)
                        .map(
                          (o) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '- ${o.toString()}',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.stemMutedText,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                  if (showTimer) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Time left: $timeStr',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.stemEmerald,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answerController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.stemLightText),
                    decoration: InputDecoration(
                      labelText: 'Your answer',
                      labelStyle: const TextStyle(color: AppColors.stemMutedText),
                      filled: true,
                      fillColor: AppColors.stemInputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Submit answer',
                    onPressed: _answerController.text.trim().isEmpty
                        ? null
                        : () async {
                            await context.read<GroupGameCubit>().submitAnswer(
                                  answerText: _answerController.text,
                                );
                            if (mounted) _answerController.clear();
                          },
                  ),
                ],
              );
            }),
            if (!needsAnswerFirst) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _questionController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.stemLightText),
                decoration: InputDecoration(
                  labelText: 'Your question',
                  labelStyle: const TextStyle(color: AppColors.stemMutedText),
                  filled: true,
                  fillColor: AppColors.stemInputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: aiGenerating ? '...' : 'AI (favorite)',
                      height: 44,
                      onPressed: aiGenerating
                          ? null
                          : () async {
                            final last = game.lastQuestion();
                            final needsAnswer = last != null &&
                                (last['answererId']?.toString() == uid) &&
                                ((last['answerText']?.toString().trim() ?? '').isEmpty);
                            if (needsAnswer) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Answer the previous question first'),
                                ),
                              );
                              return;
                            }
                            try {
                              final q = await context
                                  .read<GroupGameCubit>()
                                  .generateQuestion(favoriteMode: true);
                              if (q != null && mounted) {
                                _questionController.text = q;
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            }
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      text: aiGenerating ? '...' : 'AI (random)',
                      height: 44,
                      onPressed: aiGenerating
                          ? null
                          : () async {
                            final last = game.lastQuestion();
                            final needsAnswer = last != null &&
                                (last['answererId']?.toString() == uid) &&
                                ((last['answerText']?.toString().trim() ?? '').isEmpty);
                            if (needsAnswer) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Answer the previous question first'),
                                ),
                              );
                              return;
                            }
                            try {
                              final q = await context
                                  .read<GroupGameCubit>()
                                  .generateQuestion(favoriteMode: false);
                              if (q != null && mounted) {
                                _questionController.text = q;
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            }
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _optionControllers[i],
                    style: const TextStyle(color: AppColors.stemLightText),
                    decoration: InputDecoration(
                      labelText: 'Option ${i + 1}',
                      labelStyle: const TextStyle(color: AppColors.stemMutedText),
                      filled: true,
                      fillColor: AppColors.stemInputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                );
              }),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                value: _correctOptionIndex,
                decoration: InputDecoration(
                  labelText: 'Correct option',
                  labelStyle: const TextStyle(color: AppColors.stemMutedText),
                  filled: true,
                  fillColor: AppColors.stemInputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                dropdownColor: AppColors.stemCard,
                style: GoogleFonts.manrope(color: AppColors.stemLightText),
                items: List.generate(
                  4,
                  (i) => DropdownMenuItem<int>(
                    value: i,
                    child: Text('Option ${i + 1}'),
                  ),
                ),
                onChanged: (v) => setState(() => _correctOptionIndex = v),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Submit question',
                onPressed: _questionController.text.trim().isEmpty ||
                        _correctOptionIndex == null ||
                        _optionControllers.any((c) => c.text.trim().isEmpty)
                    ? null
                    : () async {
                        await context.read<GroupGameCubit>().submitQuestion(
                              questionText: _questionController.text,
                              options: _optionControllers
                                  .map((c) => c.text.trim())
                                  .toList(),
                              correctOptionIndex: _correctOptionIndex!,
                            );
                        if (mounted) {
                          _questionController.clear();
                          for (final c in _optionControllers) {
                            c.clear();
                          }
                          setState(() => _correctOptionIndex = null);
                        }
                      },
              ),
            ],
                ],
              );
            }),
          ],
        ],
        if (game.status == GroupGameStatus.completed) ...[
          if (game.winnerFirstId == null && isHost)
            _WinnerForm(
              memberIds: game.memberOrder,
              names: names,
              onSubmit: (a, b, c) {
                context.read<GroupGameCubit>().setWinners(
                      firstId: a,
                      secondId: b,
                      thirdId: c,
                    );
              },
            )
          else ...[
            Text(
              'Results',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.stemLightText,
              ),
            ),
            const SizedBox(height: 12),
            _podiumRow('1st', game.winnerFirstId, names),
            _podiumRow('2nd', game.winnerSecondId, names),
            _podiumRow('3rd', game.winnerThirdId, names),
          ],
        ],
      ],
    );
  }

  Widget _podiumRow(String rank, String? id, Map<String, String> names) {
    if (id == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              rank,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: AppColors.stemEmerald,
              ),
            ),
          ),
          Text(
            names[id] ?? id,
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: AppColors.stemLightText,
            ),
          ),
        ],
      ),
    );
  }
}

class _WinnerForm extends StatefulWidget {
  final List<String> memberIds;
  final Map<String, String> names;
  final void Function(String first, String second, String third) onSubmit;

  const _WinnerForm({
    required this.memberIds,
    required this.names,
    required this.onSubmit,
  });

  @override
  State<_WinnerForm> createState() => _WinnerFormState();
}

class _WinnerFormState extends State<_WinnerForm> {
  String? first;
  String? second;
  String? third;

  @override
  Widget build(BuildContext context) {
    final ids = widget.memberIds.toSet().toList();
    if (ids.length < 3) {
      return Text(
        'Need at least 3 members to rank top 3.',
        style: GoogleFonts.manrope(color: AppColors.stemMutedText),
      );
    }
    first ??= ids[0];
    second ??= ids.length > 1 ? ids[1] : ids[0];
    third ??= ids.length > 2 ? ids[2] : ids[0];

    DropdownButtonFormField<String> field(String label, String? value, void Function(String?) onChanged) {
      return DropdownButtonFormField<String>(
        value: value,
        dropdownColor: AppColors.stemCard,
        style: GoogleFonts.manrope(color: AppColors.stemLightText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.stemMutedText),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppColors.stemInputBg,
        ),
        items: ids
            .map(
              (id) => DropdownMenuItem(
                value: id,
                child: Text(widget.names[id] ?? id),
              ),
            )
            .toList(),
        onChanged: onChanged,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pick 1st, 2nd, and 3rd place',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.stemLightText,
          ),
        ),
        const SizedBox(height: 12),
        field('1st place', first, (v) => setState(() => first = v)),
        const SizedBox(height: 8),
        field('2nd place', second, (v) => setState(() => second = v)),
        const SizedBox(height: 8),
        field('3rd place', third, (v) => setState(() => third = v)),
        const SizedBox(height: 16),
        AppButton(
          text: 'Save winners',
          onPressed: first != null &&
                  second != null &&
                  third != null &&
                  first != second &&
                  second != third &&
                  first != third
              ? () => widget.onSubmit(first!, second!, third!)
              : null,
        ),
      ],
    );
  }
}
