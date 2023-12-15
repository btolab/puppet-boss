# Deploy role to target
plan boss::apply (
  TargetSpec $targets,
  String     $role,
  Boolean    $noop = false,
) {
  get_targets($targets).each() |$target| {
    $result = $target.apply_prep(_run_as => root)

    $apply_result = apply($target, _noop => $noop, _catch_errors => true, _run_as => root) {
      include "boss::role::${role}"
    }

    $apply_result.each |$result| {
      if 'logs' in $result.report {
        $result.report['logs'].each |$log| {
          out::message("${log['level'].upcase}: ${log['source']} | ${log['message']}")
        }
      }
      if ! $result.ok {
        fail_plan($result.error)
      }
    }
  }
}
