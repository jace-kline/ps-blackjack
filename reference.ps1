
class Person {
    # Properties
    [string] $Name
    [int] $Age

    # Constructor with optional parameters
    Person([string] $name = "John Doe", [int] $age = 20) {
        $this.Name = $name
        $this.Age = $age
    }
}
  
# Create a person object with default values
$person1 = New-Object Person

# Create a person object with specific values
$person2 = New-Object Person -Name "Jane Smith" -Age 30


class BlackjackPlayer {
    # Properties
    [int] $HandTotal  # Total value of cards in player's hand
    [bool] $Busted  # Flag indicating if player has busted

    # Methods
    # AddCard - Adds a card value to the player's hand and updates total
    [void] AddCard($cardValue) {
        $this.HandTotal += $cardValue
        if ($this.HandTotal -gt 21 -and (Get-Member -MemberType Property -InputObject $this).Name -contains "Ace") {
            # If hand is over 21 but contains an Ace, convert Ace to 1
            $this.HandTotal -= 10
        }
        $this.Busted = $this.HandTotal -gt 21
    }

    # ShowHand - Displays the cards in the player's hand and total value
    [void] ShowHand() {
        Write-Host "Player Hand:"
        foreach ($card in ($this.Cards)) {
            Write-Host "  - $card"
        }
        Write-Host "  Total: $($this.HandTotal)"
    }
}