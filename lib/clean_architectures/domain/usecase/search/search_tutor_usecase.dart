import 'package:flutter_base_clean_architecture/clean_architectures/data/models/app_error.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/entities/topic/topic.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/repositories/app_repostiories.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/repositories/tutor_repositories.dart';
import 'package:injectable/injectable.dart';

@injectable
class SearchTutorUseCase {
  final AppRepositories _appRepositories;
  final TutorRepositories _tutorRepositories;
  SearchTutorUseCase(this._appRepositories, this._tutorRepositories);

  SingleResult<List<Topic>> getTopics() => _appRepositories.getTopics();
}
