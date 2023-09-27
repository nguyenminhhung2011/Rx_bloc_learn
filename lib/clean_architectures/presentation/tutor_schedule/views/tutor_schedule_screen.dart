import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:rxdart_ext/rxdart_ext.dart';
import 'package:flutter_base_clean_architecture/core/components/constant/handle_time.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/lettutor/not_found_field.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/lettutor/schedule_item.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/loading_page.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/range_date_picker_custom.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_base_clean_architecture/app_coordinator.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/entities/schedule/schedule.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/presentation/tutor_schedule/bloc/tutor_schedule_bloc.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/presentation/tutor_schedule/bloc/tutor_schedule_state.dart';
import 'package:flutter_base_clean_architecture/core/components/extensions/context_extensions.dart';

class TutorScheduleScreen extends StatefulWidget {
  const TutorScheduleScreen({super.key});

  @override
  State<TutorScheduleScreen> createState() => _TutorScheduleScreenState();
}

class _TutorScheduleScreenState extends State<TutorScheduleScreen> {
  TutorScheduleBloc get _bloc => BlocProvider.of<TutorScheduleBloc>(context);

  Object? listen;

  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get _primaryColor => Theme.of(context).primaryColor;

  final RangeDateController _rangeDateController = RangeDateController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    listen ??= _bloc.state$.flatMap(handleState).collect();

    _bloc.fetchTutorSchedule();
  }

  void _selectedTime() async {
    final result = await context.pickRangeDate(_rangeDateController);
    if (result?.isNotEmpty ?? false) {
      _bloc.selectedTime(result!.first, result.last);
    }
  }

  @override
  void dispose() {
    _rangeDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: context.titleLarge.color),
        ),
        title: Text(
          'Tutor schedule',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          StreamBuilder<Map<String, DateTime>>(
            stream: Rx.combineLatest2(_bloc.startTime$, _bloc.endTime$,
                (sT, eT) => {'sT': sT, 'eT': eT}),
            builder: (ctx, sS) {
              final sT = sS.data?['sT'] ??
                  DateTime.now().subtract(const Duration(days: 1));
              final eT =
                  sS.data?['eT'] ?? DateTime.now().add(const Duration(days: 5));
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _selectedTime,
                    child: Text(
                      '${getYmdFormat(sT)} - ${getYmdFormat(eT)}',
                      style: context.titleSmall.copyWith(
                          fontWeight: FontWeight.w600, color: _primaryColor),
                    ),
                  )
                ],
              );
            },
          ),
          StreamBuilder<bool?>(
            stream: _bloc.loading$,
            builder: (ctx, sS) {
              final loading = sS.data ?? false;
              if (loading) {
                return Expanded(
                  child: Center(
                    child: StyleLoadingWidget.foldingCube
                        .renderWidget(size: 40.0, color: _primaryColor),
                  ),
                );
              }
              return StreamBuilder<List<Schedule>>(
                stream: _bloc.schedule$,
                builder: (ctx1, sS1) {
                  final data = sS1.data ?? <Schedule>[];
                  if (data.isEmpty) {
                    return const Expanded(child: NotFoundField());
                  }
                  return _itemField(data);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Expanded _itemField(List<Schedule> data) {
    return Expanded(
      child: ListView(
        children: [
          ...data.map(
            (e) => ScheduleItem(schedule: e, onPress: () {}),
          )
        ],
      ),
    );
  }

  Stream handleState(state) async* {
    if (state is GetTutorScheduleSuccess) {
      log("🌟[Get tutor schedule] success");
      return;
    }
    if (state is GetTutorScheduleFailed) {
      log("🌟 ${state.toString()}");
      return;
    }
  }
}
