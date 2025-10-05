// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
 
contract MatchingPennies {
    struct Player {
        bool present; // si hago playersMapping[add] con una address que no esta, present sera 0
        bool guessed;
        bool revealed;
        bool choice;
        bytes32 secret;
        uint256 balance; //balance que tiene para hacer withdraw
    }
 
    bool player1Ready;
    bool player2Ready;
 
    address player1Address;
    address player2Address;
 
    // si pasa cierto tiempo cualquiera puede resetear el juego
    uint256 public deadline;
 
    mapping(address => Player) public playersMapping;
 
    function updateSecret(address player, bytes32 _secret) private {
        require(
            !playersMapping[player].guessed,
            "No podes adivinar dos veces!"
        );
        playersMapping[player].secret = _secret;
        playersMapping[player].guessed = true;
    }
 
    function updateBalance(address player) private {
        playersMapping[player].balance += 0.2 ether;
    }
 
    function guess(bytes32 secret) public payable {
        require(
            playersMapping[msg.sender].present,
            "Solo pueden adivinar los jugadores de este juego"
        );
        require(msg.value == 0.1 ether, "Para jugar se debe enviar 0.1 ether");
        require(
            player1Ready && player2Ready,
            "Ambos jugadores deben estar listos para empezar a jugar"
        );
 
        updateSecret(msg.sender, secret);
    }
 
    function resetPlayer(address _playerAddress) private {
        playersMapping[_playerAddress].present = false;
        playersMapping[_playerAddress].guessed = false;
        playersMapping[_playerAddress].revealed = false;
        playersMapping[_playerAddress].choice = false;
        playersMapping[_playerAddress].secret = 0;
    }
 
    function revealSecret(bool _choice, bytes32 secret) public {
        // require(_choice == 1 || _choice == 0, "solo se puede elegir cero o uno");
        require(
            playersMapping[msg.sender].present,
            "Solo puede revelar su eleccion un jugador del juego"
        );
        require(
            playersMapping[msg.sender].secret ==
                keccak256(abi.encodePacked(_choice, secret)),
            "El secreto y choice deben ser los ingresados originalmente"
        );
 
        playersMapping[msg.sender].revealed = true;
        playersMapping[msg.sender].choice = _choice;
 
        //si ambos ya revelaron puedo actualizar el balance del ganador
        if (
            playersMapping[player1Address].revealed &&
            playersMapping[player2Address].revealed
        ) {
            bool choice1 = playersMapping[player1Address].choice;
            bool choice2 = playersMapping[player2Address].choice;
            if (choice1 == choice2) {
                updateBalance(player1Address);
            } else {
                updateBalance(player2Address);
            }
            //resetear a los jugadores y "desconectarlos" del juego
            resetPlayer(player1Address);
            resetPlayer(player2Address);
            player1Ready = false;
            player2Ready = false;
        }
    }
 
    function withdraw() public {
        require(
            playersMapping[msg.sender].balance > 0,
            "El balance debe ser mayor a cero"
        );
 
        uint256 balance = playersMapping[msg.sender].balance;
        playersMapping[msg.sender].balance = 0;
        payable(msg.sender).transfer(balance);
    }
 
    function joinGame() public {
        require(!player1Ready || !player2Ready, "Ya hay dos jugadores");
 
        if (!player1Ready) {
            player1Address = msg.sender;
            playersMapping[player1Address].present = true;
            player1Ready = true;
        } else if (!player2Ready) {
            player2Address = msg.sender;
            playersMapping[player2Address].present = true;
            player2Ready = true;
            //cuando se une el segundo jugador pongo un deadline
            deadline = block.timestamp + 24 hours;
        }
    }
    //para evitar
    // 1. Que un jugador no deje que juegue nadie
    // 2. que cuando un jugador revele el otro no lo haga porque sabe que perdio
    function restartGame() public {
        require(block.timestamp > deadline, "Deben pasar 24 horas");
        require(player1Ready && player2Ready, "No hay ningun juego en curso");
        //si algun jugador ya revelo y el otro hizo guess pero no revelo damos como ganador al que revelo
        if (playersMapping[player1Address].revealed) {
            // gana por abandono  1
            updateBalance(player1Address);
        } else if (playersMapping[player2Address].revealed) {
            // gana por abandono  2
            updateBalance(player2Address);
        }
        //si uno guessea y el otro no al pasarse el limite tiene la oportunidad de recuperar sus fondos
        else if (
            playersMapping[player1Address].guessed &&
            !playersMapping[player2Address].guessed
        ) {
            playersMapping[player1Address].balance += 0.1 ether;
        } else if (
            playersMapping[player2Address].guessed &&
            !playersMapping[player1Address].guessed
        ) {
            playersMapping[player2Address].balance += 0.1 ether;
        }
 
        //si ambos guessean pero ninguno revela o ninguno guessea el contrato se queda los fondos para penalizarlos
 
        resetPlayer(player1Address);
        resetPlayer(player2Address);
        player1Ready = false;
        player2Ready = false;
    }
}