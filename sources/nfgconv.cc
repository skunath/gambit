//
// FILE: nfgconv.cc -- Convert between types of normal forms
//
// $Id$
//


#include "nfg.h"
#include "nfplayer.h"
#include "nfstrat.h"
#include "nfgciter.h"
#include "rational.h"

Nfg<gRational> *ConvertNfg(const Nfg<double> &orig)
{
  Nfg<gRational> *N = new Nfg<gRational>(orig.NumStrats());
  
  N->GameForm().SetTitle(orig.GameForm().GetTitle());

  for (int pl = 1; pl <= N->NumPlayers(); pl++)  {
    NFPlayer *p1 = orig.Players()[pl];
    NFPlayer *p2 = N->Players()[pl];

    p2->SetName(p1->GetName());
    
    for (int st = 1; st <= p2->NumStrats(); st++)
      p2->Strategies()[st]->name = p1->Strategies()[st]->name;
  }
  
  for (int outc = 1; outc <= orig.NumOutcomes(); outc++)  {
    NFOutcome *outcome = 
      (outc > 1) ? N->GameForm().NewOutcome() : N->Outcomes()[1];

    for (int pl = 1; pl <= N->NumPlayers(); pl++)
      N->SetPayoff(outcome, pl, gRational(orig.Payoff(orig.Outcomes()[outc], pl)));
  }
		       
  NFSupport S1(orig.GameForm());
  NFSupport S2(N->GameForm());

  NfgContIter C1(S1);
  NfgContIter C2(S2);
  
  do   {
    C2.SetOutcome(N->Outcomes()[C1.GetOutcome()->GetNumber()]);

    C2.NextContingency();
  } while (C1.NextContingency());

  return N;
}



Nfg<double> *ConvertNfg(const Nfg<gRational> &orig)
{
  Nfg<double> *N = new Nfg<double>(orig.NumStrats());
  
  N->GameForm().SetTitle(orig.GameForm().GetTitle());

  for (int pl = 1; pl <= N->NumPlayers(); pl++)  {
    NFPlayer *p1 = orig.Players()[pl];
    NFPlayer *p2 = N->Players()[pl];

    p2->SetName(p1->GetName());
    
    for (int st = 1; st <= p2->NumStrats(); st++)
      p2->Strategies()[st]->name = p1->Strategies()[st]->name;
  }

  for (int outc = 1; outc <= orig.NumOutcomes(); outc++)  {
    NFOutcome *outcome = 
      (outc > 1) ? N->GameForm().NewOutcome() : N->Outcomes()[1];

    for (int pl = 1; pl <= N->NumPlayers(); pl++)
      N->SetPayoff(outcome, pl, (double) orig.Payoff(orig.Outcomes()[outc], pl));
  }

  NFSupport S1(orig.GameForm());
  NFSupport S2(N->GameForm());

  NfgContIter C1(S1);
  NfgContIter C2(S2);
  
  do   {
    C2.SetOutcome(N->Outcomes()[C1.GetOutcome()->GetNumber()]);

    C2.NextContingency();
  } while (C1.NextContingency());

  return N;
}



