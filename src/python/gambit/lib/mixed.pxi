cdef class MixedStrategyProfileDouble:
    cdef c_MixedStrategyProfileDouble *profile

    def __dealloc__(self):
        del_MixedStrategyProfileDouble(self.profile)

    def __len__(self):
        return self.profile.MixedProfileLength()

    def __repr__(self):
        return str(list(self))

    def __getitem__(self, index):
        if isinstance(index, int):
            return self.profile.getitem_int(index+1)
        elif isinstance(index, Strategy):
            return self.profile.getitem_Strategy((<Strategy>index).strategy)
        elif isinstance(index, Player):
            class MixedStrategy(object):
                def __init__(self, profile, player):
                    self.profile = profile
                    self.player = player
                def __len__(self):
                    return len(self.player.strategies)
                def __repr__(self):
                    return str(list(self.profile[self.player]))
                def __getitem__(self, index):
                    return self.parent[self.player.strategies[index]]
                def __setitem__(self, index, value):
                    self.parent[self.player.strategies[index]] = value
            return MixedStrategy(self, index)
        elif isinstance(index, str):
            try:
                # first check to see if string is referring to a player
                return self[self.game.players[index]]
            except IndexError:
                pass
            # if no player matches, check strategy labels
            strategies = reduce(lambda x,y: x+y,
                                [ p.strategies for p in self.game.players ])
            matches = filter(lambda x: x.label==index, strategies)
            if len(matches) == 1:
                return self[matches[0]]
            elif len(matches) == 0:
                raise IndexError("no player or strategy matching label '%s'" % index)
            else:
                raise IndexError("multiple strategies matching label '%s'" % index)
        else:
            raise TypeError("profile indexes must be int, str, Player, or Strategy, not %s" %
                            index.__class__.__name__)

    def __setitem__(self, index, value):
        if isinstance(index, int):
            setitem_MixedStrategyProfileDouble_int(self.profile, index+1, value)
        elif isinstance(index, Strategy):
            setitem_MixedStrategyProfileDouble_Strategy(self.profile, 
                                                        (<Strategy>index).strategy, value)
        elif isinstance(index, str):
            strategies = reduce(lambda x,y: x+y,
                                [ p.strategies for p in self.game.players ])
            matches = filter(lambda x: x.label==index, strategies)
            if len(matches) == 1:
                setitem_MixedStrategyProfileDouble_Strategy(self.profile, 
                                                           (<Strategy>
                                                            matches[0])
                                                            .strategy, value)
            elif len(matches) == 0:
                raise IndexError("no player or strategy matching label '%s'" % index)
            else:
                raise IndexError("multiple strategies matching label '%s'" % index)
        else:
            raise TypeError("profile indexes must be int, str, or Strategy, not %s" %
                            index.__class__.__name__)

    def __richcmp__(MixedStrategyProfileDouble self, other, whichop):
        if whichop == 0:
            return list(self) < list(other)
        elif whichop == 1:
            return list(self) <= list(other)
        elif whichop == 2:
            return list(self) == list(other)
        elif whichop == 3:
            return list(self) != list(other)
        elif whichop == 4:
            return list(self) > list(other)
        else:
            return list(self) >= list(other)

    property game:
        def __get__(self):
            cdef Game g
            g = Game()
            g.game = self.profile.GetGame()
            return g

    def payoff(self, player):
        if isinstance(player, Player):
            return self.profile.GetPayoff((<Player>player).player)
        elif isinstance(player, (int, str)):
            return self.payoff(self.game.players[player])
        raise TypeError("profile payoffs index must be int, str, or Player, not %s" %
                        player.__class__.__name__)

    def strategy_value(self, strategy):
        cdef Strategy s
        s = Strategy()
        
        if isinstance(strategy, Strategy):
            s = strategy
            return self.profile.GetStrategyValue(s.strategy)
        elif isinstance(strategy, str):
            return self.strategy_value(
                       [item for strategy_list in 
                       [y for y in [x.strategies for x in self.game.players]] 
                       for item in strategy_list if item.label == strategy][0])
            
    def strategy_values(self, player):
        if isinstance(player, str):
            player = self.game.players[player]
        return [self.strategy_value(item) for item in player.strategies]

    def liap_value(self):
        return self.profile.GetLiapValue()
