import 'package:flutter_bloc/flutter_bloc.dart';

class PollState {
  final int option1Votes;
  final int option2Votes;
  final int option3Votes;
  final Set<String> votedUserIds;
  final Map<int, List<String>>
      optionVoters; // Maps option number to a list of user IDs

  PollState({
    required this.option1Votes,
    required this.option2Votes,
    required this.option3Votes,
    required this.votedUserIds,
    required this.optionVoters,
  });

  PollState copyWith({
    int? option1Votes,
    int? option2Votes,
    int? option3Votes,
    Set<String>? votedUserIds,
    Map<int, List<String>>? optionVoters,
  }) {
    return PollState(
      option1Votes: option1Votes ?? this.option1Votes,
      option2Votes: option2Votes ?? this.option2Votes,
      option3Votes: option3Votes ?? this.option3Votes,
      votedUserIds: votedUserIds ?? this.votedUserIds,
      optionVoters: optionVoters ?? this.optionVoters,
    );
  }
}

class PollCubit extends Cubit<PollState> {
  PollCubit()
      : super(PollState(
            option1Votes: 0,
            option2Votes: 0,
            option3Votes: 0,
            votedUserIds: {},
            optionVoters: {1: [], 2: [], 3: []}));

  void vote(int option, String userid) {
    if (!state.votedUserIds.contains(userid)) {
      if (option == 1) {
        emit(state.copyWith(option1Votes: state.option1Votes + 1));
      } else if (option == 2) {
        emit(state.copyWith(option2Votes: state.option2Votes + 1));
      } else if (option == 3) {
        emit(state.copyWith(option3Votes: state.option3Votes + 1));
      }

      final updatedVotedUserIds = Set<String>.from(state.votedUserIds)
        ..add(userid);

      final updatedOptionVoters =
          Map<int, List<String>>.from(state.optionVoters);
      updatedOptionVoters[option] =
          List<String>.from(state.optionVoters[option]!)..add(userid);

      emit(state.copyWith(
        votedUserIds: updatedVotedUserIds,
        optionVoters: updatedOptionVoters,
      ));
    }
  }

  bool hasVoted(String userid) {
    return state.votedUserIds.contains(userid);
  }
}
