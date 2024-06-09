<#
    Class representing a playing card (suit, name)
#>
class PlayingCard {
    # Valid suit options
    static [string[]] $ValidSuits = @("Spades", "Hearts", "Diamonds", "Clubs")

    # Valid card name options
    static [string[]] $ValidNames = @("Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King")

    # Properties
    [string] $Suit  # Suit of the card (e.g., "Spades", "Hearts", "Diamonds", "Clubs")
    [string] $Name  # Name of the card (e.g., "Ace", "2", "Queen", "King")

    # Constructor (to set suit and name with validation)
    PlayingCard([string] $suit, [string] $name) {
        if (-not ([PlayingCard]::ValidSuits -contains $suit)) {
            Throw "Invalid suit. Valid suits are: $([PlayingCard]::ValidSuits -join ', ')"
        }
        if (-not ([PlayingCard]::ValidNames -contains $name)) {
            Throw "Invalid card name. Valid names are: $([PlayingCard]::ValidNames -join ', ')"
        }
        $this.Suit = $suit
        $this.Name = $name
    }

    # Method to display the card (suit and name)
    [void] DisplayCard() {
        Write-Host "Card: $($this.Name) of $($this.Suit)"
    }
}


<#
    Class representing choosing cards from N card decks
    Each draw eliminates that card from draws (until reset)
    Reset -> allows all cards to be drawn again
#>

class PlayingCardDeck {

    # Properties
    [int] $NumDecks  # Number of decks included in this collection
    [PlayingCard[]] $Cards  # Array to store PlayingCard objects
    [bool[]] $DrawnCards  # Boolean array to track drawn cards (True = drawn, False = not drawn)

    # Constructor (to set number of decks)
    PlayingCardDeck([int] $numDecks) {
        if ($numDecks -le 0) {
            Throw "Invalid number of decks. Must be greater than zero."
        }
        $this.NumDecks = $numDecks

        # Calculate total number of cards
        # $totalCards = [PlayingCard]::ValidSuits.Length * [PlayingCard]::ValidNames.Length * $numDecks

        # Initialize arrays
        [PlayingCard[]] $this.Cards = @()
        [bool[]] $this.DrawnCards = @()

        # Create all cards from all decks and add them to Cards list
        foreach ($suit in [PlayingCard]::ValidSuits) {
            foreach ($name in [PlayingCard]::ValidNames) {
                for ($i = 0; $i -lt $numDecks; $i++) {
                    $card = [PlayingCard]::new($suit, $name)
                    $this.Cards += $card
                    $this.DrawnCards += $false  # Mark card as not drawn initially
                }
            }
        }
    }

    [int[]] GetAvailableCardIndices() {
        [int[]] $availableIndices = @()
        for ($i = 0; $i -lt $this.DrawnCards.Count; $i++) {
            if (-not $this.DrawnCards[$i]) {
              $availableIndices += $i
            }
        }
        return $availableIndices
    }

    # Method to draw a random card
    [PlayingCard] DrawCard() {
        $availableIndices = $this.GetAvailableCardIndices()  # Get indexes of undrawn cards (False in DrawnCards)
        if ($availableIndices.Count -eq 0) {
            Throw "No more cards to draw. Please reset the deck."
        }
        $randomIndex = Get-Random -Minimum 0 -Maximum ($availableIndices.Count - 1)
        $drawnIndex = $availableIndices[$randomIndex]

        $this.DrawnCards[$drawnIndex] = $True  # Mark drawn card as True
        return $this.Cards[$drawnIndex]
    }

    # Method to reset the deck (clears drawn cards flag)
    [void] Reset() {
        $this.DrawnCards = [bool[]]::new($this.Cards.Length)  # Create new Boolean array with False values
    }
}

class BlackjackHand {
    # Properties
    [PlayingCard[]] $Cards  # Array to store PlayingCard objects in the hand
    [bool] $Busted  # Flag indicating if the hand is busted
    [int] $Wager  # Initial wager amount associated with the hand
    [bool] $Locked  # Flag indicating if no more actions can be taken

    # Constructor
    BlackjackHand([int] $wager) {
        if ($wager -lt 0) {
            Throw "Invalid wager. Must be nonnegative."
        }
        $this.Cards = @()  # Initialize empty array for cards
        $this.Busted = $false  # Initially not busted
        $this.Wager = $wager  # Set initial wager
        $this.Locked = $false  # Initially not locked
    }

    # Method to add a card to the hand
    [void] AddCard([PlayingCard] $card) {
        $this.Cards += $card  # Add card object to the Cards array
        $this.UpdateHandValue()  # Recalculate hand value after adding a card
    }

    static [int] GetCardsValue([PlayingCard[]] $cards) {
        $totalValue = 0
        foreach ($card in $cards) {
            switch ($card.Name) {
                "Ace" {
                    # Consider Ace as 1 if total value would bust otherwise
                    if ($totalValue + 11 -gt 21) {
                        $totalValue += 1
                    } else {
                        $totalValue += 11
                    }
                }
                # Default case for face cards (King, Queen, Jack)
                { $_ -in @("King", "Queen", "Jack") } {
                    $totalValue += 10
                }
                # Default case for numbered cards (value as string converted to int)
                default {
                    $totalValue += [int] $card.Name
                }
            }
        }
        return $totalValue
    }

    # Method to calculate the maximum hand value (considering Ace as 1 or 11)
    [int] GetHandValue() {
        return [BlackjackHand]::GetCardsValue($this.Cards)
    }

    # Internal method to update hand value and bust status after adding a card
    [void] UpdateHandValue() {
        $this.Busted = $this.GetHandValue() -gt 21  # Update bust flag based on hand value
        if (-not $this.Locked) {
            $this.Locked = $this.Busted  # Lock the hand if busted
        }
    }

    # Method to split the hand if the cards are the same value and splitting is allowed
    [BlackjackHand[]] Split([PlayingCard] $card) {
        if ($this.Cards.Count -ne 2 -or $this.Cards[0].Name -ne $card.Name) {
            Throw "Cannot split a hand that doesn't have two matching cards."
        }

        # Create two new hands and split the cards and wager
        $hand1 = [BlackjackHand]::new($this.Wager / 2)
        $hand2 = [BlackjackHand]::new($this.Wager / 2)
        $hand1.AddCard($this.Cards[0])
        $hand2.AddCard($this.Cards[1])
        $hand2.AddCard($card)  # Add the new card drawn after splitting to hand2

        return @($hand1, $hand2)
    }

    # Method to take a hit (add a card) from the deck
    [void] Hit([PlayingCardDeck] $deck) {
        if ($this.Cards.Count -ge 5 -or $this.Locked) {
            Throw "Cannot hit a hand with 5 or more cards or a locked hand."
        }
        $this.AddCard($deck.DrawCard())
    }

    # Method to indicate the player chooses to stand (no more hits)
    [void] Stand() {
        $this.Locked = $true  # Lock the hand after standing
    }

    # Method to double down (optional, doubles wager for one additional card)
    [BlackjackHand] DoubleDown([PlayingCardDeck] $deck) {
        if ($this.Cards.Count -ne 2) {
            Throw "Cannot double down on a hand with less than 2 or more than 2 cards."
        }
        # Lock the hand
        $this.Locked = $true
        # Double the wager (assuming Wager property exists)
        $this.Wager *= 2
        # Add one card and return the modified hand
        $this.AddCard($deck.DrawCard())
        return $this
    }

    # Method to display the current state of the hand
    [void] DisplayHand() {
        Write-Host "Wager: $($this.Wager)"
        Write-Host "Hand Cards:"
        foreach ($card in $this.Cards) {
            Write-Host "  - $($card.Name) of $($card.Suit)"
        }
        Write-Host "Hand Value: $($this.GetHandValue())"
        if ($this.Busted) {
            Write-Host "**BUSTED**"
        } else {
            if ($this.Locked) {
                Write-Host "**Hand Locked**"
            }
        }
    }
}

class BlackjackDealerHand : BlackjackHand {
    # Constructor
    BlackjackDealerHand() : base(0) {} # Dealer doesn't have a wager

    # Override the GetHandValue method to consider soft 17 for the dealer
    [int] GetHandValue() {
        $value = ([BlackjackHand]$this).GetHandValue() # Call parent class GetHandValue
        if ($value -eq 17 - 1 - 10  -and $this.Cards.Count -eq 3) {  # Check for soft 17 (Ace + 6) with 3 cards
            return 17
        }
        return $value
    }

    # Method for the dealer to take a hit based on game rules (dealer hits until 17 or higher)
    [void] TakeHit([PlayingCardDeck] $deck) {
        while ($this.GetHandValue() -lt 17) {
            $this.AddCard($deck.DrawCard())
        }
    }

    # Method to display the dealer's hand with only the first card visible
    [void] DisplayDealerHand([bool] $preplay = $true) {
        Write-Host "Dealer Hand:"
        $i = 0
        $seenCards = @()
        foreach ($card in $this.Cards) {
            if ($i -eq 1 -and $preplay) {
                Write-Host "  - (**hidden**)"  # Hide the second card
            } else {
                Write-Host "  - $($card.Name) of $($card.Suit)"
                $seenCards += $card
            }
            $i++
        }

        $seenCardsValue = [BlackjackHand]::GetCardsValue($seenCards)
        if ($this.Busted) {
            Write-Host "**BUSTED**"
        }
        
        if ($preplay) {
            Write-Host "Hand Value: (unknown, at least $seenCardsValue)"  # Don't reveal full value
        } else {
            Write-Host "Hand Value: $($this.GetHandValue())"
        }
    }
}

class BlackjackPlayer {
    # Properties
    [string] $Name  # Player's name

    # Money management properties
    [int] $TotalWager  # Total wager amount across all games
    [int] $ProfitLoss  # Total profit/loss across all games (TotalWager - Winnings from rounds)

    # Constructor
    BlackjackPlayer([string] $name) {
        $this.Name = $name
        $this.TotalWager = 0
        $this.ProfitLoss = 0
    }

    # Method to update player's wager for a round
    [void] PlaceWager([int] $wagerAmount) {
        if ($wagerAmount -le 0) {
            Throw "Invalid wager. Must be greater than zero."
        }
        $this.TotalWager += $wagerAmount
    }

    # Method to update player's profit/loss after a round (considering win/loss amount)
    [void] UpdateProfitLoss([int] $winnings) {
        $this.ProfitLoss += $winnings - $this.TotalWager  # Winnings - Total wager for the round
    }

    # Method to display the player's current statistics
    [void] DisplayStatistics() {
        Write-Host "Player: $($this.Name)"
        Write-Host "  Total Wager: $($this.TotalWager)"
        Write-Host "  Profit/Loss: $($this.ProfitLoss)"
    }
}

class PlayBlackjackHand {
    # Properties
    [BlackjackPlayer] $Player  # Player object representing the current player
    [BlackjackHand] $Hand # Hand that the player plays
    [BlackjackDealerHand] $Dealer  # Dealer object representing the dealer
    [PlayingCardDeck] $Deck  # Deck of cards used for the game

    # Constructor
    PlayBlackjackHand([BlackjackPlayer] $player, [PlayingCardDeck] $deck) {
        $this.Player = $player
        $this.Dealer = [BlackjackDealerHand]::new()
        $this.Deck = $deck
    }

    # Method to deal two cards to the player and two cards to the dealer (one hidden)
    [void] DealCards() {
        $this.Hand.AddCard($this.Deck.DrawCard())
        $this.Hand.AddCard($this.Deck.DrawCard())
        $this.Dealer.AddCard($this.Deck.DrawCard())
        $this.Dealer.AddCard($this.Deck.DrawCard())  # Second card hidden for dealer
    }

    # Method to handle the player's actions (hit, stand, double down, split) during their turn
    [void] PlayPlayerTurn() {
        while ($this.Hand.Cards.Count -lt 5 -and !$this.Hand.Locked) {  # Player can hit until 5 cards or hand locked
            Write-Host ""  # Newline for readability
            $this.Hand.DisplayHand()
            Write-Host ""
            $this.Dealer.DisplayDealerHand($true)  # Show only dealer's first card
            Write-Host ""

            Write-Host "What's your action?"
            $action = Read-Host "(Hit, Stand, Double Down, Split)"
            switch ($action.ToLower()) {
                "hit" {
                    $this.Hand.Hit($this.Deck)
                    break
                }
                "stand" {
                    $this.Hand.Stand()
                    break
                }
                "double down" {
                    $this.Hand.DoubleDown($this.Deck)
                    break
                }
                "split" {
                    if ($this.Hand.Cards.Count -eq 2 -and $this.Hand.Cards[0].Name -eq $this.Hand.Cards[1].Name) {
                        $splitHands = $this.Hand.Split($this.Deck.DrawCard())
                        $this.PlaySplitHands($splitHands)
                    } else {
                        Write-Host "Splitting is only allowed for two cards of the same value."
                    }
                    break
                }
                default {
                    Write-Host "Invalid action. Please choose Hit, Stand, Double Down, or Split."
                }
            }
        }
    }

    # Method to handle the dealer's turn (taking hits based on game rules)
    [void] PlayDealerTurn() {
        $this.Dealer.TakeHit($this.Deck)
    }

    # Method to determine the winner and update player's profit/loss
    [void] DetermineWinner() {
        $playerValue = $this.Hand.GetHandValue()
        $dealerValue = $this.Dealer.GetHandValue()

        Write-Host ""  # Newline for readability
        $this.Hand.DisplayHand()
        $this.Dealer.DisplayDealerHand($false)  # Reveal all dealer cards now

        if (($this.Hand.Busted -and $this.Dealer.Busted) -or ($playerValue -eq $dealerValue)) {
            Write-Host "**Push (Tie)**"
            $this.Player.UpdateProfitLoss($this.Player.TotalWager)  # Player gets the wager amount back
        } elseif ($this.Hand.Busted) {
            Write-Host "**You BUSTED!**"
            $this.Player.UpdateProfitLoss(- $this.Player.TotalWager)  # Player loses the wager amount
        } elseif ($this.Dealer.Busted) {
            Write-Host "**DEALER BUSTED! You Win!**"
            $this.Player.UpdateProfitLoss($this.Player.TotalWager * 2)  # Player wins double the wager
        } elseif ($playerValue -gt $dealerValue) {
            Write-Host "**You Win!**"
            $this.Player.UpdateProfitLoss($this.Player.TotalWager * 1.5)  # Player wins 1.5 times the wager (common payout)
        } else {
            Write-Host "**You Lose!**"
            $this.Player.UpdateProfitLoss(- $this.Player.TotalWager)  # Player loses the wager amount
        }
    }

    # Method to play split hands after the player chooses to split
    [void] PlaySplitHands([BlackjackHand[]] $splitHands) {
        foreach ($hand in $splitHands) {
            Write-Host "**Playing Split Hand**"
            $this.PlayPlayerTurn($hand)  # Recursively call PlayPlayerTurn for each split hand
            $this.PlayDealerTurn()  # Play dealer turn after each split hand
            $this.DetermineWinner($hand)  # Determine winner for each split hand
        }
    }

    [int] PromptWager() {
        $wager = [int] (Read-Host "Enter your wager amount: ")
        $this.Player.PlaceWager($wager)  # Update player's total wager for entire play history
        return $wager
    }

    # Method to play a single hand of Blackjack
    [void] Run() {

        $wager = $this.PromptWager()
        $this.Hand = [BlackjackHand]::new($wager)

        $this.DealCards()  # Deal two cards to player and two cards to dealer (one hidden)

        $this.PlayPlayerTurn()  # Handle player's actions (hit, stand, double down, split)

        $this.PlayDealerTurn()  # Handle dealer's turn (taking hits based on game rules)

        $this.DetermineWinner()  # Determine winner and update player's profit/loss
    }
}

class PlayBlackjack {
    # Properties
    [BlackjackPlayer] $Player  # Player object representing the current player

    # Constructor
    PlayBlackjack() {
        Write-Host "Welcome to Blackjack!"
        $playerName = Read-Host "Enter your name: "
        $this.Player = [BlackjackPlayer]::new($playerName)  # Create player object with name
    }

    # Method to display the main menu
    [void] DisplayMenu() {
        Write-Host ""
        Write-Host "Welcome back, $($this.Player.Name)!"
        Write-Host ""
        Write-Host "1. Play Blackjack"
        Write-Host "2. View Statistics"
        Write-Host "3. Exit"
    }

    # Method to handle playing a single round of Blackjack
    [void] PlayRound() {
        $deck = [PlayingCardDeck]::new(1)  # Create a new deck for each round
        $game = [PlayBlackjackHand]::new($this.Player, $deck)
        $game.Run()

        Write-Host ""  # Newline for readability after round ends
    }

    # Method to display the player's current statistics
    [void] ViewStatistics() {
        $this.Player.DisplayStatistics()
    }

    # Main loop to keep playing rounds until the user exits
    [void] Run() {
        [bool] $exit = $false
        while (-not $exit) {
            $this.DisplayMenu()
            $choice = Read-Host "Enter your choice: "
            switch ($choice) {
                "1" {
                    $this.PlayRound()
                    break
                }
                "2" {
                    $this.ViewStatistics()
                    break
                }
                "3" {
                    $exit = $true
                    break
                }
                default {
                    Write-Host "Invalid choice. Please enter 1, 2, or 3."
                }
            }

            if($exit) { break }
        }
        Write-Host ""
        Write-Host "Thank you for playing Blackjack, $($this.Player.Name)!"
        Write-Host "Final statistics..."
        $this.ViewStatistics()
    }
}

function Main {
    $game = [PlayBlackjack]::new()  # Create a PlayBlackjack object
    $game.Run()  # Call the Run method to start the game loop
}

Main  # Call the Main function to start the game