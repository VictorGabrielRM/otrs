# --
# Kernel/System/ProcessManagement/TransitionAction/CustomerSet.pm - A Module to set the ticket customer
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: CustomerSet.pm,v 1.2 2012-11-12 18:39:05 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.
# --

package Kernel::System::ProcessManagement::TransitionAction::CustomerSet;

use strict;
use warnings;
use Kernel::System::VariableCheck qw(:all);

use utf8;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.2 $) [1];

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction::CustomerSet - A module to set a new ticket customer

=head1 SYNOPSIS

All CustomerSet functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Time;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::System::Ticket;
    use Kernel::System::ProcessManagement::TransitionAction::CustomerSet;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $TimeObject = Kernel::System::Time->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $TicketObject = Kernel::System::Ticket->new(
        ConfigObject       => $ConfigObject,
        LogObject          => $LogObject,
        DBObject           => $DBObject,
        MainObject         => $MainObject,
        TimeObject         => $TimeObject,
        EncodeObject       => $EncodeObject,
    );
    my $CustomerSetActionObject = Kernel::System::ProcessManagement::TransitionAction::CustomerSet->new(
        ConfigObject       => $ConfigObject,
        LogObject          => $LogObject,
        EncodeObject       => $EncodeObject,
        DBObject           => $DBObject,
        MainObject         => $MainObject,
        TimeObject         => $TimeObject,
        TicketObject       => $TicketObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (
        qw(ConfigObject LogObject EncodeObject DBObject MainObject TimeObject TicketObject)
        )
    {
        die "Got no $Needed!" if !$Param{$Needed};

        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

=item Run()

    Run Data

    my $CustomerSetResult = $CustomerSetActionObject->Run(
        UserID      => 123,
        Ticket      => \%Ticket, # required
        Config      => {
            CustomerID     => 'client123',
            # or
            CustomerUserID => 'client-user-123',

            #OR (Framework wording)
            No             => 'client123',
            # or
            User           => 'client-user-123',
        }
    );
    Ticket contains the result of TicketGet including DynamicFields
    Config is the Config Hash stored in a Process::TransitionAction's  Config key
    Returns:

    $CustomerSetResult = 1; # 0

    );

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(UserID Ticket Config)) {
        if ( !defined $Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # Check if we have Ticket to deal with
    if ( !IsHashRefWithData( $Param{Ticket} ) ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Ticket has no values!",
        );
        return;
    }

    # Check if we have a ConfigHash
    if ( !IsHashRefWithData( $Param{Config} ) ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Config has no values!",
        );
        return;
    }

    if (
        !$Param{Config}->{CustomerID}
        && !$Param{Config}->{No}
        && !$Param{Config}->{CustomerUserID}
        && !$Param{Config}->{User}
        )
    {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "No CustomerID/No or CustomerUserID/User configured!",
        );
        return;
    }

    if ( !$Param{Config}->{CustomerID} && $Param{Config}->{No} ) {
        $Param{Config}->{CustomerID} = $Param{Config}->{No};
    }
    if ( !$Param{Config}->{CustomerUserID} && $Param{Config}->{User} ) {
        $Param{Config}->{CustomerUserID} = $Param{Config}->{User};
    }

    if (
        defined $Param{Config}->{CustomerID}
        &&
        (
            !defined $Param{Ticket}->{CustomerID}
            || $Param{Config}->{CustomerID} ne $Param{Ticket}->{CustomerID}
        )
        )
    {
        my $Success = $Self->{TicketObject}->TicketCustomerSet(
            TicketID => $Param{Ticket}->{TicketID},
            No       => $Param{Config}->{CustomerID},
            UserID   => $Param{UserID},
        );

        if ( !$Success ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => 'Ticket CustomerID could not be updated for Ticket: '
                    . $Param{Ticket}->{TicketID} . '!',
            );
            return;
        }
    }

    if (
        defined $Param{Config}->{CustomerUserID}
        &&
        (
            !defined $Param{Ticket}->{CustomerUserID}
            || $Param{Config}->{CustomerUserID} ne $Param{Ticket}->{CustomerUserID}
        )
        )
    {
        my $Success = $Self->{TicketObject}->TicketCustomerSet(
            TicketID => $Param{Ticket}->{TicketID},
            User     => $Param{Config}->{CustomerUserID},
            UserID   => $Param{UserID},
        );

        if ( !$Success ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => 'Ticket CustomerID could not be updated for Ticket: '
                    . $Param{Ticket}->{TicketID} . '!',
            );
            return;
        }
    }

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=head1 VERSION

$Revision: 1.2 $ $Date: 2012-11-12 18:39:05 $

=cut
