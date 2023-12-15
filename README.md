# Bolt Open Source Stacks

Deploy technology stacks with [Puppet Bolt] like a BOSS.

## Table of Contents

1. [Description](#description)
1. [Setup](#setup)
1. [Usage](#usage)
1. [Limitations](#limitations)
1. [Development](#development)

## Description

There can be only one.

## Setup

```
puppet resource package puppet-bolt ensure=latest
bolt module install --force
```

## Usage

```
bolt plan run boss::apply -t puppet.labnodes.com role=puppet::server --sudo-password-prompt
```

## Limitations

Your imagination.

## Development

Is fun.

[Puppet Bolt]: https://github.com/puppetlabs/bolt
