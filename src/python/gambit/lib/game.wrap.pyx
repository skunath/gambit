cdef extern from "string":
    ctypedef struct cxx_string "string":
        char *c_str()
        cxx_string assign(char *)

cdef extern from "libgambit/libgambit.h":
    cxx_string ToText "lexical_cast<>"(c_Rational)

cdef extern from "libgambit/rational.h":
    ctypedef struct c_Rational "Rational":
        c_Rational add "operator+="(c_Rational)
        pass

    c_Rational ToRational "lexical_cast<Rational>"(cxx_string)


cdef extern from "libgambit/number.h":
    ctypedef struct c_Number "Number":
        double as_double "operator const double &"()
        c_Rational as_rational "operator const Rational &"()
        cxx_string as_string "operator const string &"()
    c_Number *new_Number "new Number"()
    c_Number *new_Number_copy "new Number"(c_Number)
    c_Number *new_Number_string "new Number"(cxx_string)
    void del_Number "delete"(c_Number *)

    int eq_Number(c_Number *, c_Number *)
    int ne_Number(c_Number *, c_Number *)
    int lt_Number(c_Number *, c_Number *)
    int le_Number(c_Number *, c_Number *)
    int gt_Number(c_Number *, c_Number *)
    int ge_Number(c_Number *, c_Number *)
    c_Number add_Number(c_Number *, c_Number *)
    c_Number sub_Number(c_Number *, c_Number *)
    c_Number mul_Number(c_Number *, c_Number *)
    c_Number div_Number(c_Number *, c_Number *)
     
cdef extern from "libgambit/array.h":
    ctypedef struct c_ArrayInt "Array<int>":
        int getitem "operator[]"(int)
    c_ArrayInt *new_ArrayInt "new Array<int>"(int)
    void del_ArrayInt "delete"(c_ArrayInt *)

cdef extern from "libgambit/game.h":
    ctypedef struct c_GameRep
    ctypedef struct c_GameStrategyRep
    ctypedef struct c_GamePlayerRep
    ctypedef struct c_GameOutcomeRep
    ctypedef struct c_GameNodeRep
    
    ctypedef struct c_Game "GameObjectPtr<GameRep>":
        c_GameRep *deref "operator->"()

    ctypedef struct c_GamePlayer "GameObjectPtr<GamePlayerRep>":
        c_GamePlayerRep *deref "operator->"()

    ctypedef struct c_GameOutcome "GameObjectPtr<GameOutcomeRep>":
        c_GameOutcomeRep *deref "operator->"()
 
    ctypedef struct c_GameNode "GameObjectPtr<GameNodeRep>":
        c_GameNodeRep *deref "operator->"()

    ctypedef struct c_GameStrategy "GameObjectPtr<GameStrategyRep>":
        c_GameStrategyRep *deref "operator->"()

    ctypedef struct c_GameStrategyRep "GameStrategyRep":
        int GetNumber()
        c_GamePlayer GetPlayer()

        cxx_string GetLabel()
        void SetLabel(cxx_string)

    ctypedef struct c_GamePlayerRep "GamePlayerRep":
        c_Game GetGame()
        int GetNumber()
        int IsChance()
        
        cxx_string GetLabel()
        void SetLabel(cxx_string)
        
        int NumStrategies()
        c_GameStrategy GetStrategy(int) except +IndexError

    ctypedef struct c_GameOutcomeRep "GameOutcomeRep":
        c_Game GetGame()
        int GetNumber()
        
        cxx_string GetLabel()
        void SetLabel(cxx_string)
     
        c_Number GetPayoffNumber "GetPayoff<Number>"(int) except +IndexError
        void SetPayoff(int, cxx_string) except +IndexError

    ctypedef struct c_GameNodeRep "GameNodeRep":
        c_Game GetGame()
        int GetNumber()

        cxx_string GetLabel()
        void SetLabel(cxx_string)

    ctypedef struct c_GameRep "GameRep":
        int IsTree()
        
        cxx_string GetTitle()
        void SetTitle(cxx_string)

        int NumPlayers()
        c_GamePlayer GetPlayer(int) except +IndexError
        c_GamePlayer GetChance()
        c_GamePlayer NewPlayer()

        int NumOutcomes()
        c_GameOutcome GetOutcome(int)
        
        int NumNodes()
        c_GameNode GetRoot()

    ctypedef struct c_PureStrategyProfile "PureStrategyProfile":
        c_GameStrategy GetStrategy(c_GamePlayer)
        void SetStrategy(c_GameStrategy)

        c_GameOutcome GetOutcome()
        void SetOutcome(c_GameOutcome)

    c_PureStrategyProfile *new_PureStrategyProfile "new PureStrategyProfile"(c_Game)
    void del_PureStrategyProfile "delete"(c_PureStrategyProfile *)

    c_Game NewTree()
    c_Game NewTable(c_ArrayInt *)

cdef extern from "libgambit/mixed.h":
    ctypedef struct c_MixedStrategyProfileDouble "MixedStrategyProfile<double>":
        int MixedProfileLength()
        double getitem_int "operator[]"(int) except +IndexError
        double getitem_Strategy "operator[]"(c_GameStrategy)
        double GetPayoff(c_GamePlayer)
        double GetStrategyValue(c_GameStrategy)
        double GetLiapValue()
    c_MixedStrategyProfileDouble *new_MixedStrategyProfileDouble "new MixedStrategyProfile<double>"(c_Game)
    void del_MixedStrategyProfileDouble "delete"(c_MixedStrategyProfileDouble *)

cdef extern from "game.wrap.h":
    c_Game ReadGame(char *) except +IOError
    cxx_string WriteGame(c_Game, int) except +IOError

    void setitem_ArrayInt(c_ArrayInt *, int, int)
    void setitem_MixedStrategyProfileDouble_int(c_MixedStrategyProfileDouble *, 
                                                int, double)
    void setitem_MixedStrategyProfileDouble_Strategy(c_MixedStrategyProfileDouble *, 
                                                     c_GameStrategy, double)


import gambit.gameiter

cdef class Number:
    cdef c_Number *thisptr

    def __cinit__(self, value=None):
        cdef cxx_string s
        if value is not None:
            x = str(value)
            s.assign(x)
            self.thisptr = new_Number_string(s)
        else: 
            self.thisptr = new_Number()

    def __dealloc__(self):
        del_Number(self.thisptr)

    def __repr__(self):
        cdef cxx_string s
        s = self.thisptr.as_string()
        return s.c_str()

    def __float__(self):
        return self.thisptr.as_double()        

    def __richcmp__(Number self, other, whichop):
        cdef Number othernum
        othernum = Number(other)
        if whichop == 0:
            return bool(lt_Number(self.thisptr, othernum.thisptr))
        elif whichop == 1:
            return bool(le_Number(self.thisptr, othernum.thisptr))
        elif whichop == 2:
            return bool(eq_Number(self.thisptr, othernum.thisptr))
        elif whichop == 3:
            return bool(ne_Number(self.thisptr, othernum.thisptr))
        elif whichop == 4:
            return bool(gt_Number(self.thisptr, othernum.thisptr))
        else:
            return bool(ge_Number(self.thisptr, othernum.thisptr))

    def __add__(self, other):
        cdef c_Number result
        cdef Number ret
        cdef Number selfnum
        cdef Number othernum
        selfnum = Number(self)
        othernum = Number(other)
        result = add_Number(selfnum.thisptr, othernum.thisptr)
        ret = Number()
        del_Number(ret.thisptr)
        ret.thisptr = new_Number_copy(result)
        return ret
        
    def __sub__(self, other):
        cdef c_Number result
        cdef Number ret
        cdef Number selfnum
        cdef Number othernum
        selfnum = Number(self)
        othernum = Number(other)
        result = sub_Number(selfnum.thisptr, othernum.thisptr)
        ret = Number()
        del_Number(ret.thisptr)
        ret.thisptr = new_Number_copy(result)
        return ret
        
    def __mul__(self, other):
        cdef c_Number result
        cdef Number ret
        cdef Number selfnum
        cdef Number othernum
        selfnum = Number(self)
        othernum = Number(other)
        result = mul_Number(selfnum.thisptr, othernum.thisptr)
        ret = Number()
        del_Number(ret.thisptr)
        ret.thisptr = new_Number_copy(result)
        return ret
        
    def __div__(self, other):
        cdef c_Number result
        cdef Number ret
        cdef Number selfnum
        cdef Number othernum
        selfnum = Number(self)
        othernum = Number(other)
        result = div_Number(selfnum.thisptr, othernum.thisptr)
        ret = Number()
        del_Number(ret.thisptr)
        ret.thisptr = new_Number_copy(result)
        return ret
        

cdef class Strategy:
    cdef c_GameStrategy strategy

    def __repr__(self):
        return "<Strategy [%d] '%s' for player '%s' in game '%s'>" % \
                (self.strategy.deref().GetNumber()-1, self.label,
                 self.strategy.deref().GetPlayer().deref().GetLabel().c_str(),
                 self.strategy.deref().GetPlayer().deref().GetGame().deref().GetTitle().c_str())
    
    def __richcmp__(Strategy self, other, whichop):
        if isinstance(other, Strategy):
            if whichop == 2:
                return self.strategy.deref() == ((<Strategy>other).strategy).deref()
            elif whichop == 3:
                return self.strategy.deref() != ((<Strategy>other).strategy).deref()
            else:
                raise NotImplementedError
        else:
            if whichop == 2:
                return False
            elif whichop == 3:
                return True
            else:
                raise NotImplementedError

    def __hash__(self):
        return long(<long>self.strategy.deref())

    property label:
        def __get__(self):
            return self.strategy.deref().GetLabel().c_str()
        def __set__(self, char *value):
            cdef cxx_string s
            s.assign(value)
            self.strategy.deref().SetLabel(s)

    
cdef class Strategies:
    cdef c_GamePlayer player

    def __repr__(self):
        return str(list(self))

    def __len__(self):
        return self.player.deref().NumStrategies()

    def __getitem__(self, st):
        cdef Strategy s
        if st < 0 or st >= len(self):
            raise IndexError("no strategy with index '%s'" % st)
        s = Strategy()
        s.strategy = self.player.deref().GetStrategy(st+1)
        return s

cdef class Player:
    cdef c_GamePlayer player

    def __repr__(self):
        if self.is_chance:
            return "<Player [CHANCE] in game '%s'>" % self.player.deref().GetGame().deref().GetTitle().c_str()
        return "<Player [%d] '%s' in game '%s'>" % (self.player.deref().GetNumber()-1,
                                                    self.label,
                                                    self.player.deref().GetGame().deref().GetTitle().c_str())
    
    def __richcmp__(Player self, other, whichop):
        if isinstance(other, Player):
            if whichop == 2:
                return self.player.deref() == ((<Player>other).player).deref()
            elif whichop == 3:
                return self.player.deref() != ((<Player>other).player).deref()
            else:
                raise NotImplementedError
        else:
            if whichop == 2:
                return False
            elif whichop == 3:
                return True
            else:
                raise NotImplementedError

    def __hash__(self):
        return long(<long>self.player.deref())

    property label:
        def __get__(self):
            return self.player.deref().GetLabel().c_str()
        def __set__(self, char *value):
            cdef cxx_string s
            s.assign(value)
            self.player.deref().SetLabel(s)

    property is_chance:
        def __get__(self):
            return True if self.player.deref().IsChance() != 0 else False

    property strategies:
        def __get__(self):
            cdef Strategies s
            s = Strategies()
            s.player = self.player
            return s
    
cdef class Players:
    cdef c_Game game

    def __repr__(self):
        return str(list(self))

    def __len__(self):
        return self.game.deref().NumPlayers()

    def __getitem__(self, pl):
        cdef Player p
        if pl < 0 or pl >= len(self):
            raise IndexError("no player with index '%s'" % pl)
        p = Player()
        p.player = self.game.deref().GetPlayer(pl+1)
        return p

    def add(self, label=""):
        cdef Player p
        p = Player()
        p.player = self.game.deref().NewPlayer()
        p.label = str(label)
        return p

    property chance:
        def __get__(self):
            cdef Player p
            p = Player()
            p.player = self.game.deref().GetChance()
            return p

cdef class Outcome:
    cdef c_GameOutcome outcome

    def __repr__(self):
        return "<Outcome [%d] '%s' in game '%s'>" % (self.outcome.deref().GetNumber()-1,
                                                     self.label,
                                                     self.outcome.deref().GetGame().deref().GetTitle().c_str())
    
    def __richcmp__(Outcome self, other, whichop):
        if isinstance(other, Outcome):
            if whichop == 2:
                return self.outcome.deref() == ((<Outcome>other).outcome).deref()
            elif whichop == 3:
                return self.outcome.deref() != ((<Outcome>other).outcome).deref()
            else:
                raise NotImplementedError
        else:
            if whichop == 2:
                return False
            elif whichop == 3:
                return True
            else:
                raise NotImplementedError

    def __hash__(self):
        return long(<long>self.outcome.deref())

    property label:
        def __get__(self):
            return self.outcome.deref().GetLabel().c_str()
        def __set__(self, char *value):
            cdef cxx_string s
            s.assign(value)
            self.outcome.deref().SetLabel(s)

    def __getitem__(self, pl):
        cdef Number number
        number = Number()
        number.thisptr = new_Number_copy(self.outcome.deref().GetPayoffNumber(pl+1))
        return number

    def __setitem__(self, pl, value):
        cdef cxx_string s
        v = str(value)
        s.assign(v)
        self.outcome.deref().SetPayoff(pl+1, s)
        
       
cdef class Outcomes:
    cdef c_Game game

    def __repr__(self):
        return "<Outcomes of game '%s'>" % self.game.deref().GetTitle().c_str()

    def __len__(self):
        return self.game.deref().NumOutcomes()

    def __getitem__(self, outc):
        cdef Outcome c
        if outc < 0 or outc >= len(self):
            raise IndexError("no outcome with index '%s'" % outc)
        c = Outcome()
        c.outcome = self.game.deref().GetOutcome(outc+1)
        return c


cdef class Node:
    cdef c_GameNode node

    def __repr__(self):
        return "<Node [%d] '%s' in game '%s'>" % (self.node.deref().GetNumber(),
                                                  self.label,
                                                  self.node.deref().GetGame().deref().GetTitle().c_str())
    
    def __richcmp__(Node self, other, whichop):
        if isinstance(other, Node):
            if whichop == 2:
                return self.node.deref() == ((<Node>other).node).deref()
            elif whichop == 3:
                return self.node.deref() != ((<Node>other).node).deref()
            else:
                raise NotImplementedError
        else:
            if whichop == 2:
                return False
            elif whichop == 3:
                return True
            else:
                raise NotImplementedError

    def __hash__(self):
        return long(<long>self.node.deref())


    property label:
        def __get__(self):
            return self.node.deref().GetLabel().c_str()
        def __set__(self, char *value):
            cdef cxx_string s
            s.assign(value)
            self.node.deref().SetLabel(s)

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
            return [ self[s] for s in index.strategies ]
        else:
            raise TypeError, "unexpected type passed to __getitem__ on strategy profile"

    def __setitem__(self, index, value):
        if isinstance(index, int):
            setitem_MixedStrategyProfileDouble_int(self.profile, index+1, value)
        elif isinstance(index, Strategy):
            setitem_MixedStrategyProfileDouble_Strategy(self.profile, 
                                                        (<Strategy>index).strategy, value)
        else:
            raise TypeError, "unexpected type passed to __getitem__ on strategy profile"

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

    def payoff(self, Player player):
        return self.profile.GetPayoff(player.player)

    def strategy_value(self, Strategy strategy):
        return self.profile.GetStrategyValue(strategy.strategy)

    def liap_value(self):
        return self.profile.GetLiapValue()


cdef class Game:
    cdef c_Game game

    def __str__(self):
        return "<Game '%s'>" % self.title

    def __repr__(self):
        return self.write()

    def __richcmp__(Game self, other, whichop):
        if isinstance(other, Game):
            if whichop == 2:
                return self.game.deref() == ((<Game>other).game).deref()
            elif whichop == 3:
                return self.game.deref() != ((<Game>other).game).deref()
            else:
                raise NotImplementedError
        else:
            if whichop == 2:
                return False
            elif whichop == 3:
                return True
            else:
                raise NotImplementedError

    def __hash__(self):
        return long(<long>self.game.deref())

    property is_tree:
        def __get__(self):
            return True if self.game.deref().IsTree() != 0 else False

    property title:
        def __get__(self):
            return self.game.deref().GetTitle().c_str()
        def __set__(self, char *value):
            cdef cxx_string s
            s.assign(value)
            self.game.deref().SetTitle(s)

    property players:
        def __get__(self):
            cdef Players p
            p = Players()
            p.game = self.game
            return p

    property outcomes:
        def __get__(self):
            cdef Outcomes c
            c = Outcomes()
            c.game = self.game
            return c

    property contingencies:
        def __get__(self):
            return gambit.gameiter.Contingencies(self)

    property root:
        def __get__(self):
            cdef Node n
            n = Node()
            n.node = self.game.deref().GetRoot()
            return n

    def _get_contingency(self, *args):
        cdef c_PureStrategyProfile *psp
        cdef Outcome outcome
        psp = new_PureStrategyProfile(self.game)

        for (pl, st) in enumerate(args):
            psp.SetStrategy(self.game.deref().GetPlayer(pl+1).deref().GetStrategy(st+1))

        outcome = Outcome()
        outcome.outcome = psp.GetOutcome()
        del_PureStrategyProfile(psp)
        return outcome

    # As of Cython 0.11.2, cython does not support the * notation for the argument
    # to __getitem__, which is required for multidimensional slicing to work. 
    # We work around this by providing a shim.
    def __getitem__(self, i):
        return self._get_contingency(*i)

    def mixed_profile(self):
        cdef MixedStrategyProfileDouble msp
        msp = MixedStrategyProfileDouble()
        msp.profile = new_MixedStrategyProfileDouble(self.game)
        return msp
 
    def num_nodes(self):
        return self.game.deref().NumNodes()

    def write(self, strategic=False):
        if strategic or not self.is_tree:
            return WriteGame(self.game, 1).c_str()
        else:
            return WriteGame(self.game, 0).c_str()


def new_tree():
    cdef Game g
    g = Game()
    g.game = NewTree()
    return g

def new_table(dim):
    cdef Game g
    cdef c_ArrayInt *d
    d = new_ArrayInt(len(dim))
    for i in range(1, len(dim)+1):
        setitem_ArrayInt(d, i, dim[i-1])
    g = Game()
    g.game = NewTable(d)
    del_ArrayInt(d)
    return g

def read_game(char *fn):
    cdef Game g
    g = Game()
    try:
        g.game = ReadGame(fn)
    except IOError:
        raise IOError("Unable to read game from file '%s'" % fn)
    return g
        
