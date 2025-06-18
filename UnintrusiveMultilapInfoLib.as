/*
* Author: TigerHelos
*/

namespace Tracker {
    // Properties
    bool _inGame = false;
    string _currentMapId = "";
    int _currentLap = 0;
    int _maxLap = 0;
    int _maxLap2 = 0;
    int _bestLapTest = 0;
    int _averageLap = 0;

    // Getters
    bool get_inGame() property { return _inGame; }
    string get_currentMapId() property { return _currentMapId; }
    int get_currentLap() property { return _currentLap; }
    int get_maxLap() property { return _maxLap; }
    int get_bestLapTest() property { return _bestLapTest; }
    int get_averageLap() property { return _averageLap; }

    void Main(){
        // Initalize stuff here if needed.
    }

    void Update(){
        // Determine wheter user is in a game.
        auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
		
		if(playground is null
			|| playground.Arena is null
			|| playground.Map is null
			|| playground.GameTerminals.Length <= 0
			|| playground.GameTerminals[0].UISequence_Current != CGamePlaygroundUIConfig::EUISequence::Playing
			|| cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer) is null) {
			_inGame = false;
			return;
		}

        // Get the player either playing or that is being spectated.
		auto player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
		auto scriptPlayer = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer).ScriptAPI;
		
        // If no script pleyer, we cannot calculate the Best and Average lap times.
		if(scriptPlayer is null) {
			_inGame = false;
			return;
		}
		if(player.CurrentLaunchedRespawnLandmarkIndex == uint(-1)) {
			_inGame = true;
		}

        // Set up current information about the map.
        if(!_inGame && (_currentMapId != playground.Map.IdName || GetApp().Editor !is null)) {
			_currentMapId = playground.Map.IdName;
			_currentLap = 0;
            _maxLap = playground.Map.TMObjective_IsLapRace ? playground.Map.TMObjective_NbLaps : 1;
        }

        // Get MLFeed data about the race (raceData) and player (racePlayer).
        auto raceData = MLFeed::GetRaceData_V4();
        auto racePlayer = raceData.GetPlayer_V4(scriptPlayer.Name);
        if (racePlayer is null){
            return;
        }

        _maxLap2 = raceData.LapsNb;
        // Only enable the plugin if the race actually has multiple laps.
        bool isMultiLap = (_maxLap > 1 || _maxLap2 > 1);
        if (!isMultiLap) {
            _inGame = false;
            return;
        }
        _inGame = true;

        // Get all times at all checkpoints for player.
        auto cpTimes = racePlayer.CpTimes;

        // Calculate the number of full laps completed by the player.
        auto fullLaps = Math::Floor((cpTimes.Length-1)/(raceData.CPCount+1));

        // Calculate every lap time from the cpTimes.
        array<int> laps = {};
        if (fullLaps > 0){
            for (int i = 0; i < fullLaps; i++){
                auto lapTime = cpTimes[(raceData.CPCount+1)*(i+1)] - cpTimes[(raceData.CPCount+1)*i];
                laps.InsertLast(lapTime);
            }
        }

        // If no laps are done, set best and average lap times to zero (0).
        if (laps.Length == 0 && (_bestLapTest != 0 || _averageLap != 0)){
            _bestLapTest = 0;
            _averageLap = 0;
            return;
        }

        // Find best lap time and calculate average lap time.
        if (laps.Length > 0){
            laps.SortAsc();
            _bestLapTest = laps[0];
            _averageLap = CalculateAverage(laps);
        }
    }

    // Utility method for calculating the average time.
    int CalculateAverage(array<int> laps) {
        uint total = 0;
        for (uint i = 0; i < laps.Length; i++) {
            total += laps[i];
        }
        return int(Math::Round(total / laps.Length));
    }
}