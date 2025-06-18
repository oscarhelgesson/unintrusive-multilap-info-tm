/*
* Author: TigerHelos
*/

[Setting name="Show Best (Session) Lap"]
bool showBestLap = true;

[Setting name="Show Average Lap"]
bool showAverageLap = true;

[Setting name="Font size"]
int fontSize = 38;

[Setting name="Anchor X position"]
float anchorX = .984;

[Setting color name="Normal color"]
vec4 colorNormal = vec4(1, 1, 1, 1);

[Setting name="Best Lap Anchor Y position"]
float BestLapAnchorY = .542;

[Setting name="Y position offset"]
float YOffset = 0.035;

[Setting category="Display Settings" name="Hide when the game interface is hidden"]
bool hideWithIFace = false;

[Setting category="Display Settings" name="Hide when the Openplanet overlay is hidden"]
bool hideWithOverlay = false;

int font;

#if DEPENDENCY_MLFEEDRACEDATA
bool g_mlfeedDetected = true;
#else
bool g_mlfeedDetected = false;
#endif

#if DEPENDENCY_MLHOOK
bool g_mlhookDetected = true;
#else
bool g_mlhookDetected = false;
#endif

void Main(){
    // Make sure that the dependencies are loaded before anything else.
    trace("MLHook detected: " + tostring(g_mlhookDetected));
    trace("MLFeed detected: " + tostring(g_mlfeedDetected));

    if (!(g_mlfeedDetected && g_mlhookDetected)) {
        if (!g_mlhookDetected) {
            NotifyDepError("Requires MLHook");
        }
        if (!g_mlfeedDetected) {
            NotifyDepError("Requires MLFeed: Race Data");
        }
        while (true) sleep(10000);
    }

    // Import and activate font.
    LoadFont();

    // Start tracking times.
    Tracker::Main();
}

void Update(float dt){
    // Use the update of the Tracking class.
    Tracker::Update();
}

void RenderMenu() {
    // Button for activating best lap time text.
    if (UI::MenuItem("\\$09f" + Icons::Flag + "\\$z Show Race Best Lap", "", showBestLap, true)) {
        showBestLap = !showBestLap;
    }
    // Button for activating best lap time text.
    if (UI::MenuItem("\\$C90" + Icons::Flag + "\\$z Show Race Average Lap", "", showAverageLap, true)) {
        showAverageLap = !showAverageLap;
    }
    
}

void Render(){
    
    // If the Plugin should be shown at all.
	if(hideWithIFace && !UI::IsGameUIVisible()) {
		return;
	}
	
	if(hideWithOverlay && !UI::IsOverlayShown()) {
		return;
	}

    if (!Tracker::get_inGame()){
        return;
    }

    if (!showBestLap && !showAverageLap){
        return;
    }

    // Set text attributes.
    nvg::FontSize(fontSize);
    nvg::FontFace(font);
    nvg::TextAlign(nvg::Align::Right | nvg::Align::Top);

    // If showBestLap is activated, Render Best Lap.
    if (showBestLap){
        string bestLapText = GetBestLapText();
        DisplayText(bestLapText, anchorX, BestLapAnchorY);
    }

    // If showAverageLap is activated, Render Average Lap.
    if (showAverageLap){
        uint prev = showBestLap ? 1 : 0;
        string averageLapText = GetAverageLapText();
        DisplayText(averageLapText, anchorX, BestLapAnchorY+(YOffset*prev));
    }
}

// Method for diplaying certain text with shadow at a specific location.
void DisplayText(const string &in text, float x, float y) {
    nvg::FillColor(vec4(0, 0, 0, 1));
    int shadowOffset = 3;
    nvg::Text(x * Draw::GetWidth() + shadowOffset, y * Draw::GetHeight() + shadowOffset, text);

    nvg::FillColor(colorNormal);
    nvg::Text(x * Draw::GetWidth(), y * Draw::GetHeight(), text);
}

// Gets the current best time (formatted) from the Tracker.
string GetBestLapText(){
    string bestTime = format_time(Tracker::get_bestLapTest());
    return "Best Lap: " + bestTime;
}

// Gets the current average lap time (formatted) from the tracker.
string GetAverageLapText(){
    string averageTime = format_time(Tracker::get_averageLap());
    return "Average Lap: " + averageTime;
}

// Utils

// Loads the font.
void LoadFont() {
    font = nvg::LoadFont("assets/Oswald-Regular.ttf");
}

// Notifies the user if a dependency is missing.
void NotifyDepError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Dependency Error", msg, vec4(.9, .6, .1, .5), 15000);
}

// Formats the time (calculated in milliseconds) to suitable format.
string format_time(uint64 total_milliseconds) {
    int milliseconds = total_milliseconds % 1000;
    int total_seconds = total_milliseconds / 1000;
    int seconds = total_seconds % 60;
    int total_minutes = total_seconds / 60;
    int minutes = total_minutes % 60;
    int hours = total_minutes / 60;

    if (hours > 0) {
        return formatInt(hours) + ":" + formatInt(minutes) + ":" + formatInt(seconds) + "." + formatInt(milliseconds, true);
    } else if (minutes > 0) {
        return formatInt(minutes) + ":" + formatInt(seconds) + "." + formatInt(milliseconds, true);
    } else {
        return formatInt(seconds) + "." + formatInt(milliseconds, true);
    }
}

// Helper function to format integers with leading zeros
string formatInt(int value, bool milli = false) {
    if (milli){
        if(value < 10){
            return '00'+value;
        } else if (value < 100){
            return '0'+value;
        } else {
            return ''+value;
        }
    }
    if (value < 10){
        return '0' + value;
    } else {
        return '' + value;
    }
}