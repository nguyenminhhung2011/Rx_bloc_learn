import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/entities/boo_info/boo_info.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/entities/pagination/pagination.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/presentation/schedule/bloc/schedule_bloc.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/presentation/schedule/bloc/schedule_state.dart';
import 'package:flutter_base_clean_architecture/core/components/extensions/context_extensions.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/lettutor/boo_info_item.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/lettutor/not_found_field.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/loading_page.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/pagination_view/default_pagination.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  ScheduleBloc get _bloc => BlocProvider.of<ScheduleBloc>(context);

  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get _primaryColor => Theme.of(context).primaryColor;

  Object? listen;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      animationDuration: const Duration(milliseconds: 300),
      length: 2,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    listen ??= _bloc.state$.flatMap(handleState).collect();

    _bloc.getBooInfo();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool?>(
      stream: _bloc.loading$,
      builder: (ctx, sS) {
        final loading = sS.data ?? false;
        return Stack(
          children: [
            _body(context),
            if (loading)
              Container(
                color: Colors.black45,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: _loading(),
              )
          ],
        );
      },
    );
  }

  Scaffold _body(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.school, color: _primaryColor),
            Text(
              ' Schedule',
              style: context.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _bloc.refreshData(),
        child: StreamBuilder(
          stream: _bloc.history$,
          builder: (ctx, sS) {
            final history = sS.data;
            if (history == null) {
              return const NotFoundField();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  tabs: [
                    ...['UpComing', 'History']
                        .map((e) => Tab(text: e, height: 40.0))
                  ],
                  controller: _tabController,
                  onTap: (value) => _bloc.changeTab(value),
                  padding: const EdgeInsets.all(10.0),
                  physics: const BouncingScrollPhysics(),
                  indicatorPadding: const EdgeInsets.all(0.0),
                  isScrollable: true,
                  unselectedLabelStyle: context.titleSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).hintColor,
                  ),
                  unselectedLabelColor: Theme.of(context).hintColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  splashBorderRadius: BorderRadius.circular(5.0),
                  splashFactory: NoSplash.splashFactory,
                  labelColor: Colors.white,
                  labelStyle: context.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  indicator: BoxDecoration(
                    border: Border.all(width: 1, color: _primaryColor),
                    borderRadius: BorderRadius.circular(5.0),
                    color: _primaryColor,
                  ),
                ),
                StreamBuilder<int>(
                  stream: _bloc.tab$,
                  builder: (ctx1, sS1) {
                    final tab = sS1.data ?? 0;
                    return Expanded(
                      child:
                          _listHBooInfoField(history: history, currentTab: tab),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _listHBooInfoField(
      {required Pagination<BooInfo> history, required int currentTab}) {
    if (history.rows.isEmpty) {
      return const NotFoundField();
    }
    return DefaultPagination(
      items: history.rows,
      loading: false,
      itemBuilder: (_, index) {
        return BooInfoItem(
          booInfo: (history.rows[index] as BooInfo),
          isHistoryType: currentTab == 1,
        );
      },
      listenScrollBottom: () => _bloc.getBooInfo(),
    );
  }

  Center _loading() {
    return Center(
      child: StyleLoadingWidget.foldingCube
          .renderWidget(size: 40.0, color: _primaryColor),
    );
  }

  Stream handleState(state) async* {
    if (state is GetBooInfoSuccess) {
      log("🌆[Get boo history] success");
      return;
    }
    if (state is GetBooInfoFailed) {
      log("🌆 ${state.toString()}");
      return;
    }
  }
}
