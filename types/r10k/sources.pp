# @summary r10k sources
#
# @param name
# @param source
#
type Boss::R10k::Sources = Hash[
  Pattern[/[a-z0-9_]/],
  Boss::R10k::Source,
]
