#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'lxctl',
	MIN_PERL_VERSION => '5.010001',
	PMLIBDIRS => [qw(lib inc)],
	EXE_FILES => [qw(bin/lxctl bin/lxctl_debug)],
	LICENSE => 'GPLv2',
	AUTHOR => 'Pavel Potapenkov (oxcd8o@yandex-team.ru), Vladimir Smirnov (civil@yandex-team.ru)',
);