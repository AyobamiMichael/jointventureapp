// group_data.dart

class Group {
  final String groupname;
  final String groupid;

  Group({required this.groupname, required this.groupid});
}

List<Group> mockGroups = [
  Group(groupname: 'Enugu Boys Club', groupid: 'G001'),
  Group(groupname: 'KIC Old boys', groupid: 'G002'),
  Group(groupname: 'Scocial Women Of Nigeria', groupid: 'G003'),
];
