import 'package:disposebag/disposebag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/entities/topic/topic.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/usecase/search/search_tutor_usecase.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/presentation/search_tutor/bloc/search_tutor_state.dart';
import 'package:flutter_base_clean_architecture/core/components/utils/type_defs.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

@injectable
class SearchTutorBloc extends DisposeCallbackBaseBloc {
  ///[functions] input
  final Function0<void> fetchTopicsData;

  final Function1<Topic, void> selectedTopic;

  ///[Streams]

  final Stream<List<Topic>> topics$;

  final Stream<List<Topic>> topicSelected$;

  final Stream<bool?> loading$;

  final Stream<SearchTutorState> state$;

  SearchTutorBloc._({
    required Function0<void> dispose,
    required this.fetchTopicsData,
    required this.topicSelected$,
    required this.selectedTopic,
    required this.topics$,
    required this.loading$,
    required this.state$,
  }) : super(dispose);

  factory SearchTutorBloc({required SearchTutorUseCase searchTutorUseCase}) {
    final topicController =
        BehaviorSubject<List<Topic>>.seeded(List<Topic>.empty(growable: true));

    final topicSelectedController =
        BehaviorSubject<List<Topic>>.seeded(List<Topic>.empty(growable: true));

    final loadingController = BehaviorSubject<bool>.seeded(false);

    final fetchTopicsController = PublishSubject<void>();

    final selectedTopicController = PublishSubject<Topic>();

    final fetchTopics$ = fetchTopicsController
        .withLatestFrom(loadingController.stream, (_, loading) => !loading)
        .share();

    final selectedTopicState$ = selectedTopicController.stream.map((topic) {
      final currentSelectedTopics = topicSelectedController.value;
      if (currentSelectedTopics.contains(topic)) {
        topicSelectedController.add(
          currentSelectedTopics.where((element) => element != topic).toList(),
        );
      } else {
        topicSelectedController.add([...currentSelectedTopics, topic]);
      }
      return const SelectedTopicSuccess();
    }).share();

    final fetchTopicState$ = Rx.merge([
      fetchTopics$
          .where((isValid) => isValid)
          .debug(log: debugPrint)
          .exhaustMap((_) {
        try {
          return searchTutorUseCase
              .getTopics()
              .doOn(
                listen: () => loadingController.add(true),
                cancel: () => loadingController.add(false),
              )
              .map(
                (data) => data.fold(
                    ifLeft: (error) => FetchTopicsFailed(
                        message: error.message, error: error.code),
                    ifRight: (List<Topic> listTopic) {
                      if (listTopic.isNotEmpty) {
                        topicController.add(
                          [const Topic(name: 'All'), ...listTopic],
                        );
                      }
                      return const FetchTopicsSuccess();
                    }),
              );
        } catch (e) {
          return Stream<SearchTutorState>.error(
            FetchTopicsFailed(message: e.toString()),
          );
        }
      }),
      fetchTopics$.where((isValid) => !isValid).map(
            (_) => const InValidSearchTutor(),
          )
    ]).whereNotNull().share();

    final state$ =
        Rx.merge<SearchTutorState>([fetchTopicState$, selectedTopicState$])
            .whereNotNull()
            .share();

    return SearchTutorBloc._(
      dispose: () async => await DisposeBag([
        topicController,
        fetchTopicsController,
        loadingController,
        topicSelectedController,
        selectedTopicController
      ]).dispose(),
      fetchTopicsData: () => fetchTopicsController.add(null),
      topicSelected$: topicSelectedController,
      selectedTopic: (topic) => selectedTopicController.add(topic),
      loading$: loadingController,
      topics$: topicController,
      state$: state$,
    );
  }
}
