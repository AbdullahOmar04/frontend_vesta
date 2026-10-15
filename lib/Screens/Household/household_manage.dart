import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icon_picker.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Household/household_actions.dart';
import 'package:frontend_vesta/Screens/Household/household_data.dart';

/// A household member as the household screens show them.
typedef HouseholdMember = ({String uid, String name, String? photo});

/// The avatar colours members get, in joining order.
List<Color> householdMemberColors(VestaColors v) => [
  v.pxBlue,
  v.pxYellow,
  v.pxGreen,
  v.pxPurple,
  v.pxTeal,
];

/// A member's initial in their colour.
class MemberDot extends StatelessWidget {
  const MemberDot({
    super.key,
    required this.name,
    required this.color,
    this.photo,
    this.size = 22,
  });

  final String name;
  final Color color;
  final String? photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      backgroundImage: photo != null ? NetworkImage(photo!) : null,
      child: photo == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: size * 0.48,
                fontWeight: FontWeight.w600,
                color: context.vesta.pxInk,
              ),
            )
          : null,
    );
  }
}

/// The prototype's "New household" pop-up: an icon and a name.
Future<void> showNewHouseholdDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _NewHouseholdDialog(),
  );
}

class _NewHouseholdDialog extends StatefulWidget {
  const _NewHouseholdDialog();

  @override
  State<_NewHouseholdDialog> createState() => _NewHouseholdDialogState();
}

class _NewHouseholdDialogState extends State<_NewHouseholdDialog> {
  final _name = TextEditingController();
  String _icon = 'house-line';
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the household a name.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _creating = true);
    try {
      final db = FirebaseFirestore.instance;
      final householdRef = db.collection('households').doc();
      final batch = db.batch();
      batch.set(householdRef, {
        'householdName': name,
        'icon': _icon,
        'createdBy': uid,
        'members': [uid],
        'createdAt': FieldValue.serverTimestamp(),
        'budget': 0,
      });
      batch.update(db.collection('users').doc(uid), {
        'householdIds': FieldValue.arrayUnion([householdRef.id]),
      });
      await batch.commit();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _creating = false;
          _error = "Couldn't create the household: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VestaDialog(
      title: 'New household',
      confirmLabel: 'Create',
      onConfirm: _create,
      loading: _creating,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(
                iconKey: _icon,
                size: 52,
                fallback: PhosphorIconsRegular.houseLine,
                onTap: () async {
                  final key = await showIconPicker(context, selected: _icon);
                  if (key != null) setState(() => _icon = key);
                },
              ),
              const SizedBox(width: VestaSpace.md),
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: true,
                  maxLength: 28,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: const InputDecoration(
                    hintText: 'Household name',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: VestaSpace.sm),
            Text(
              _error!,
              style: TextStyle(fontSize: 12, color: context.vesta.neg),
            ),
          ],
        ],
      ),
    );
  }
}

/// What happened in the Edit household pop-up that the page must follow.
enum ManageResult { left, deleted }

/// The prototype's "Edit household" pop-up: icon and name, the members
/// (Leave for yourself, Remove for others when you are the admin), inviting
/// by username or email or with a link, and Delete for the admin.
Future<ManageResult?> showEditHouseholdDialog(
  BuildContext context, {
  required String householdId,
  required String name,
  required String icon,
  required List<HouseholdMember> members,
  required String? ownerUid,
  required VoidCallback onShareLink,
}) {
  return showDialog<ManageResult>(
    context: context,
    builder: (_) => _EditHouseholdDialog(
      householdId: householdId,
      name: name,
      icon: icon,
      members: members,
      ownerUid: ownerUid,
      onShareLink: onShareLink,
    ),
  );
}

class _EditHouseholdDialog extends StatefulWidget {
  const _EditHouseholdDialog({
    required this.householdId,
    required this.name,
    required this.icon,
    required this.members,
    required this.ownerUid,
    required this.onShareLink,
  });

  final String householdId;
  final String name;
  final String icon;
  final List<HouseholdMember> members;
  final String? ownerUid;
  final VoidCallback onShareLink;

  @override
  State<_EditHouseholdDialog> createState() => _EditHouseholdDialogState();
}

class _EditHouseholdDialogState extends State<_EditHouseholdDialog> {
  late final _name = TextEditingController(text: widget.name);
  final _invite = TextEditingController();
  late String _icon = widget.icon;
  late final List<HouseholdMember> _members = [...widget.members];
  bool _saving = false;
  bool _inviting = false;
  String? _inviteNote;
  bool _inviteFailed = false;
  String? _error;

  String? get _me => FirebaseAuth.instance.currentUser?.uid;
  bool get _isAdmin => widget.ownerUid != null && widget.ownerUid == _me;

  @override
  void dispose() {
    _name.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the household a name.');
      return;
    }
    if (name == widget.name && _icon == widget.icon) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      await saveHouseholdDetails(widget.householdId, name: name, icon: _icon);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Couldn't save: $e";
        });
      }
    }
  }

  Future<void> _sendInvite() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _inviting = true;
      _inviteNote = null;
    });
    try {
      final who = await inviteToHousehold(
        widget.householdId,
        householdName: widget.name,
        query: _invite.text,
      );
      _invite.clear();
      setState(() {
        _inviteFailed = false;
        _inviteNote =
            'Invite sent to $who. They can accept it in Shared finances.';
      });
    } on StateError catch (e) {
      setState(() {
        _inviteFailed = true;
        _inviteNote = e.message;
      });
    } catch (e) {
      setState(() {
        _inviteFailed = true;
        _inviteNote = "Couldn't send the invite: $e";
      });
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  Future<void> _leave() async {
    final left = await leaveHousehold(
      context,
      householdId: widget.householdId,
      name: widget.name,
    );
    if (left && mounted) Navigator.pop(context, ManageResult.left);
  }

  Future<void> _remove(HouseholdMember m) async {
    final removed = await removeHouseholdMember(
      context,
      householdId: widget.householdId,
      memberUid: m.uid,
      memberName: m.name,
    );
    if (removed && mounted) {
      setState(() => _members.removeWhere((x) => x.uid == m.uid));
    }
  }

  Future<void> _delete() async {
    final deleted = await deleteHousehold(
      context,
      householdId: widget.householdId,
      name: widget.name,
      members: _members.map((m) => m.uid).toList(),
    );
    if (deleted && mounted) Navigator.pop(context, ManageResult.deleted);
  }

  /// The small red outlined Leave / Remove button.
  Widget _redButton(String label, VoidCallback onTap) {
    final neg = context.vesta.neg;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: neg,
        side: BorderSide(color: neg),
        textStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final palette = householdMemberColors(v);
    final ownerName = _members
        .where((m) => m.uid == widget.ownerUid)
        .map((m) => m.name)
        .firstOrNull;

    return VestaDialog(
      title: 'Edit household',
      confirmLabel: 'Save',
      onConfirm: _save,
      loading: _saving,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(
                iconKey: _icon,
                size: 52,
                fallback: PhosphorIconsRegular.houseLine,
                onTap: () async {
                  final key = await showIconPicker(context, selected: _icon);
                  if (key != null) setState(() => _icon = key);
                },
              ),
              const SizedBox(width: VestaSpace.md),
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: 28,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: const InputDecoration(
                    hintText: 'Household name',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.lg),
          Text('Members', style: TextStyle(fontSize: 12, color: v.muted)),
          const SizedBox(height: VestaSpace.sm),
          Container(
            decoration: BoxDecoration(
              color: v.raised,
              borderRadius: BorderRadius.circular(VestaRadius.md),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _members.length; i++)
                  Container(
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : Border(top: BorderSide(color: v.divider)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        MemberDot(
                          name: _members[i].name,
                          photo: _members[i].photo,
                          color: palette[i % palette.length],
                          size: 32,
                        ),
                        const SizedBox(width: VestaSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: _members[i].name,
                                  children: [
                                    if (_members[i].uid == _me)
                                      TextSpan(
                                        text: ' (you)',
                                        style: TextStyle(color: v.muted),
                                      ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_members[i].uid == widget.ownerUid)
                                Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: v.accentInk,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // The admin deletes rather than leaves
                        if (_members[i].uid == _me && !_isAdmin)
                          _redButton('Leave', _leave)
                        else if (_isAdmin && _members[i].uid != _me)
                          _redButton('Remove', () => _remove(_members[i])),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_isAdmin) ...[
            const SizedBox(height: VestaSpace.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _invite,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _inviteNote = null),
                    decoration: const InputDecoration(
                      hintText: 'Username or email',
                    ),
                  ),
                ),
                const SizedBox(width: VestaSpace.sm),
                SizedBox(
                  width: 84,
                  child: PrimaryButton(
                    label: 'Invite',
                    loading: _inviting,
                    onPressed: _invite.text.trim().isEmpty ? null : _sendInvite,
                  ),
                ),
              ],
            ),
            if (_inviteNote != null) ...[
              const SizedBox(height: 6),
              Text(
                _inviteNote!,
                style: TextStyle(
                  fontSize: 12,
                  color: _inviteFailed ? v.neg : v.pos,
                ),
              ),
            ],
            const SizedBox(height: VestaSpace.sm),
            OutlinedButton.icon(
              onPressed: widget.onShareLink,
              style: OutlinedButton.styleFrom(
                foregroundColor: v.accentInk,
                side: BorderSide(color: v.accentInk.withValues(alpha: 0.6)),
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(PhosphorIconsRegular.link, size: 16),
              label: const Text('Share invite link'),
            ),
          ],
          const SizedBox(height: VestaSpace.md),
          Text(
            _isAdmin
                ? "You're the admin because you created this household. Only "
                      'the admin can add or remove members.'
                : 'Only the admin${ownerName != null ? ' ($ownerName)' : ''} '
                      'can add or remove members.',
            style: TextStyle(fontSize: 12, color: v.muted),
          ),
          if (_isAdmin)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: v.neg,
                  padding: EdgeInsets.zero,
                ),
                onPressed: _delete,
                icon: const Icon(PhosphorIconsRegular.trash, size: 16),
                label: const Text('Delete household'),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: VestaSpace.sm),
            Text(_error!, style: TextStyle(fontSize: 12, color: v.neg)),
          ],
        ],
      ),
    );
  }
}
