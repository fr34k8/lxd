test_storage_volume_import() {
  truncate -s 25MiB foo.iso
  truncate -s 25MiB foo.img

  ensure_import_testimage

  # importing an ISO as storage volume requires a volume name
  ! lxc storage volume import "lxdtest-$(basename "${LXD_DIR}")" ./foo.iso || false
  ! lxc storage volume import "lxdtest-$(basename "${LXD_DIR}")" ./foo.img --type=iso || false

  # import ISO as storage volume
  lxc storage volume import "lxdtest-$(basename "${LXD_DIR}")" ./foo.iso foo
  lxc storage volume import "lxdtest-$(basename "${LXD_DIR}")" ./foo.img --type=iso foobar
  lxc storage volume show "lxdtest-$(basename "${LXD_DIR}")" foo | grep -q 'content_type: iso'
  lxc storage volume show "lxdtest-$(basename "${LXD_DIR}")" foobar | grep -q 'content_type: iso'

  # snapshots are disabled for ISO storage volumes
  ! lxc storage volume snapshot "lxdtest-$(basename "${LXD_DIR}")" foo || false

  # backups are disabled for ISO storage volumes
  ! lxc storage volume export "lxdtest-$(basename "${LXD_DIR}")" foo || false

  # cannot attach ISO storage volumes to containers
  lxc init testimage c1
  ! lxc storage volume attach "lxdtest-$(basename "${LXD_DIR}")" c1 foo || false

  # cannot change storage volume config
  ! lxc storage volume set "lxdtest-$(basename "${LXD_DIR}")" foo size=1GiB || false

  # copy volume
  lxc storage volume copy "lxdtest-$(basename "${LXD_DIR}")"/foo "lxdtest-$(basename "${LXD_DIR}")"/bar
  lxc storage volume show "lxdtest-$(basename "${LXD_DIR}")" bar | grep -q 'content_type: iso'

  # cannot refresh copy
  ! lxc storage volume copy "lxdtest-$(basename "${LXD_DIR}")"/foo "lxdtest-$(basename "${LXD_DIR}")"/bar --refresh || false

  # can change description
  lxc storage volume show "lxdtest-$(basename "${LXD_DIR}")" foo | sed 's/^description:.*/description: foo/' | lxc storage volume edit "lxdtest-$(basename "${LXD_DIR}")" foo
  lxc storage volume show "lxdtest-$(basename "${LXD_DIR}")" foo | grep -q 'description: foo'

  # cleanup
  lxc delete -f c1
  lxc storage volume delete "lxdtest-$(basename "${LXD_DIR}")" foo
  lxc storage volume delete "lxdtest-$(basename "${LXD_DIR}")" bar
  lxc storage volume delete "lxdtest-$(basename "${LXD_DIR}")" foobar

  rm -f foo.iso foo.img
}
