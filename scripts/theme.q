
// decompiled (2024) after compiling and creating it using QueenBee and adituv/qbc (2022)

GH2_Boot_SFX_struct = $#"0xfb849dbe"
GH2_Boot_SFX_container = {
	Command = PlaySound
	Randomness = None
	Sounds = {
		Sound1 = { GH2_Boot vol = 80 }
	}
}
StarPower_Out_SFX_struct = $#"0xfb849dbe"
StarPower_Out_SFX_container = {
	Command = PlaySound
	Randomness = None
	Sounds = {
		Sound1 = { sp_lose vol = 80 }
	}
}

script set_sidebar_flash
	if ($Cheat_PerformanceMode = 1)
		return
	endif
	ExtendCrc highway_pulse_black_ ($<player_status>.text) out = pulse
	if ($<pulse> = 1)
		return
	endif
	if ($beat_flip = 0)
		return
	endif
	// about 0.005ms slower than original code
	text = ($<player_status>.text)
	ExtendCrc sidebar_left <text> out = left
	ExtendCrc sidebar_right <text> out = right
	Ternary \{$beat_flip a = '0' b = '1'}
	if ($<player_status>.star_power_used = 1)
		color = sidebar_starpower
	else
		if (<dying> = 1)
			color = sidebar_dying
		else
			if ($<player_status>.star_power_amount >= 50.0)
				color = sidebar_starready
			else
				color = sidebar_normal
			endif
		endif
	endif
	ExtendCrc <color> <ternary> out = rgba
	DoScreenElementMorph id = <left> rgba = ($<rgba>)
	DoScreenElementMorph id = <right> rgba = ($<rgba>)
	fretbars = ($<player_status>.current_song_fretbar_array)
	GetArraySize ($<fretbars>)
	if (<array_entry> < <array_size> - 1)
		time = ((($<fretbars>[(<array_entry> + 1)]) - <marker>) / 500.0)
		Ternary \{$beat_flip a = '1' b = '0'}
		ExtendCrc <color> <ternary> out = rgba
		DoScreenElementMorph id = <left> rgba = ($<rgba>) time = <time>
		DoScreenElementMorph id = <right> rgba = ($<rgba>) time = <time>
	endif
endscript

script GuitarEvent_StarPowerOn
	SpawnScriptNow highway_pulse_multiplier_loss params = {
		player_text = ($<player_status>.text)
		multiplier = 4
	}
	SpawnScriptNow GH2_StarPower_FX params = { player_status = <player_status> player = <player> }
	GH_Star_Power_Verb_On
	StarPowerOn Player = <Player>
endscript
script GH2_StarPower_FX
	Wait \{0.1 seconds}
	time = 0.0 // just to get gem sprites that barely spawned yet and put lens flare on them
	length = 0.6
	i = ($<player_status>.total_notes) // iffy
	ExtendCrc input_array ($<player_status>.text) out = array
	begin
		got_gem = 0 // lazy
		gem_time = ($<array>[<i>][0])
		time_left = (1.0 - (<time> / <length>))
		c = 0
		begin
			FormatText checksumname = gem_id '%c_%e_gem_p%p' c = ($gem_colors_text[<c>]) e = <i> p = <player>
			if ScreenElementExists id = <gem_id>
				got_gem = 1
				spawnscriptnow lnzf params = {
					gem_id = <gem_id> player_status = <player_status>
					time = <gem_time> time_left = <time_left>
				}
			endif
			Increment \{c}
		repeat 5
		if (<got_gem> = 0)
			GetDeltaTime
			time = (<time> + <delta_time>)
			if (<time> > <length>)
				break
			endif
			i = (<i> - 1)
			Wait \{1 gameframe}
		endif
		Increment \{i}
	repeat
endscript
script lnzf
	if ($Cheat_PerformanceMode = 1)
		return
	endif
	if ($#"0xe7b89f4f" != 1)
		return
	endif
	ExtendCrc <gem_id> '_particle' out = fx_id
	if ($game_mode = p2_battle || $boss_battle = 1)
		return
	endif
	if is_star_note time = <time> player_status = <player_status>
		<Pos> = (245.0, 155.0)
	else
		<Pos> = (43.0, 10.0)
	endif
	Destroy2DParticleSystem id = <fx_id>
	rgba = [ 255 255 255 255 ]
	start_opacity = (<time_left> * 255)
	CastToInteger \{start_opacity}
	SetArrayElement arrayname = rgba index = 3 newvalue = <start_opacity>
	Create2DParticleSystem {
		id = <fx_id>
		Pos = <Pos>
		z_priority = 8.0
		material = sys_Particle_lnzflare02_sys_Particle_lnzflare02
		parent = <gem_id>
		start_color = <rgba>
		end_color = [255 255 255 0]
		start_scale = (2.5, 2.5)
		end_scale = (2.5, 2.5)
		start_angle_spread = 360.0
		min_rotation = -500.0
		max_rotation = 500.0
		emit_start_radius = 0.0
		emit_radius = 0.0
		Emit_Rate = 0.02
		emit_dir = 0.0
		emit_spread = 160.0
		velocity = 0.01
		friction = (0.0, 0.0)
		time = (1.25 * <time_left>)
	}
	spawnscriptnow destroy_first_gem_fx params = {gem_id = <gem_id> fx_id = <fx_id>}
	wait \{0.05 seconds}
	Destroy2DParticleSystem id = <fx_id> kill_when_empty
endscript

whammy_top_width1 = 8.6
whammy_top_width2 = 8.2

script control_whammy_pitchshift
	if ($boss_battle = 1)
		if ($<player_status>.Player = 2)
			return
		endif
	endif
	<set_pitch> = 0
	if GotParam \{net_whammy_length}
		<len> = <net_whammy_length>
		<set_pitch> = 1
	else
		if GuitarGetAnalogueInfo controller = ($<player_status>.controller)
			<set_pitch> = 1
			if ($<player_status>.bot_play = 1)
				<len> = 0.0
			elseif IsGuitarController controller = ($<player_status>.controller)
				<len> = ((<rightx> - $<player_status>.resting_whammy_position)/ (1.0 - $<player_status>.resting_whammy_position))
				if (<len> < 0.0)
					<len> = 0.0
				endif
			else
				if (<leftlength> > 0)
					<len> = <leftlength>
				else
					if (<rightlength> > 0)
						<len> = <rightlength>
					else
						<len> = 0
					endif
				endif
			endif
			if (($is_network_game)& ($<player_status>.Player = 1))
				Change StructureName = <player_status> net_whammy = <len>
			endif
		endif
	endif
	if (<set_pitch> = 1)
		set_whammy_pitchshift control = <len> player_status = <player_status>
		<whammy_scale> = (((<len> * 1.3) + 0.5) * 2.0)
		// thought of doing a dirty hack here
		// where its executed 60 times per second
		// instead of for every single frame
		GetSongTime
		ExtendCrc wibble_lag ($<player_status>.text) out = wibble_lag
		w = ($<wibble_lag>)
		if (<songtime> > <w>)
			SetNewWhammyValue value = <whammy_scale> time_remaining = <time> player_status = <player_status> Player = (<player_status>.Player)
			change globalname = <wibble_lag> newvalue = (<songtime> + $wibble_delta)
		endif
	endif
endscript

script GuitarEvent_StarPowerOff
	SoundEvent \{ event = StarPower_Out_SFX }
	GH_Star_Power_Verb_Off
	spawnscriptnow rock_meter_star_power_off params = {player_text = <player_text>}
	ExtendCrc starpower_container_left <player_text> out = cont
	if ScreenElementExists id = <cont>
		DoScreenElementMorph id = <cont> alpha = 0
	endif
	ExtendCrc starpower_container_right <player_text> out = cont
	if ScreenElementExists id = <cont>
		DoScreenElementMorph id = <cont> alpha = 0
	endif
	ExtendCrc Highway_2D <player_text> out = highway
	if ScreenElementExists id = <highway>
		SetScreenElementProps id = <highway> rgba = ($highway_normal)
	endif
endscript
#"0x330738c4" = {
	time = 1900
	ScriptTable = [
	]
}
#"0xf0d0fb06" = {
	ScriptTable = [
		{ time = 0 Scr = play_intro }
		{ time = 1 Scr = Transition_StartRendering }
		{ time = 1 Scr = SoundEvent params = { event = #"0x417a8b50" } }
		{ time = 10 Scr = muh_arby_bot_star }
		{ time = 10 Scr = time_events }
	]
	EndWithDefaultCamera
	SyncWithNoteCameras
}
Default_Practice_Transition = {
	time = 1300
	ScriptTable = [
	]
}
Common_Practice_Transition = $Common_Immediate_Transition
intro_sequence_props = {
	song_title_pos = (0.0, 0.0)
	performed_by_pos = (0.0, 0.0)
	song_artist_pos = (0.0, 0.0)
	song_title_start_time = 0
	song_title_fade_time = 0
	song_title_on_time = 0
	highway_start_time = -1900
	highway_move_time = 2000
	button_ripple_start_time = -750
	button_ripple_per_button_time = 100
	hud_start_time = -200
	hud_move_time = 200
}

script move_highway_2d
	Change \{ start_2d_move = 0 }
	begin
		if ($start_2d_move = 1)
			break
		endif
		Wait \{ 1 gameframe }
	repeat
	highway_start_y = 470
	pos_start_orig = 0
	pos_add = -720
	elapsed_time = 0.0
	begin
		<Pos> = (((<container_pos>.(1.0, 0.0))* (1.0, 0.0))+ (<highway_start_y> * (0.0, 1.0)))
		SetScreenElementProps id = <container_id> Pos = <Pos>
		GetDeltaTime \{ ignore_slomo }
		<elapsed_time> = (<elapsed_time> + <delta_time>)
		<scaled_time> = (<elapsed_time> / 1.3)
		if (<scaled_time> > 1.0)
			<scaled_time> = 1.0
		endif
		ln (1.005 - <scaled_time>)
		<speed_modifier> = ((<ln> * 0.25)+ 1.0)
		if (<speed_modifier> < 0.05)
			<speed_modifier> = 0.05
		endif
		<highway_start_y> = (<highway_start_y> + (<pos_add> * <delta_time> * <speed_modifier>))
		if (<highway_start_y> <= <pos_start_orig>)
			<Pos> = (((<container_pos>.(1.0, 0.0))* (1.0, 0.0))+ (<pos_start_orig> * (0.0, 1.0)))
			SetScreenElementProps id = <container_id> Pos = <Pos>
			break
		endif
		Wait \{ 1 gameframe }
	repeat
endscript

script #"0xbe8220a7"
	Change current_transition = fastintro
	if ($game_mode = training)
		Change current_transition = practice
	endif
endscript

script create_score_text
	if NOT ($game_mode = p2_battle || $boss_battle = 1)
		ExtendCrc HUD2D_Score_Text <player_text> out = new_id
		ExtendCrc HUD2D_score_container <player_text> out = new_score_container
		score_text_pos = (202.0, 147.0)
		if ($game_mode = p2_career || $game_mode = p2_coop)
			<score_text_pos> = (230.0, 83.0)
		endif
		if ScreenElementExists id = <new_score_container>
			displayText {
				parent = <new_score_container>
				id = <new_id>
				font = num_a9
				Pos = <score_text_pos>
				z = 20
				Scale = (1.24, 1.0)
				just = [ right right ]
				rgba = [ 255 255 255 255 ]
			}
			SetScreenElementProps id = <id> font_spacing = 0 rot_angle = -6.4 shadow_rgba = [0 0 0 0]
		endif
		i = 1
		begin
			formatText checksumName = note_streak_text_id 'HUD2D_Note_Streak_Text_%d' d = <i>
			ExtendCrc <note_streak_text_id> <player_text> out = new_id
			ExtendCrc HUD2D_note_container <player_text> out = new_note_container
			if ScreenElementExists id = <new_note_container>
				if (<i> = 1)
					rgba = [ 15 15 70 200 ]
				else
					rgba = [ 230 230 230 200 ]
				endif
				displayText {
					parent = <new_note_container>
					id = <new_id>
					font = num_a7
					text = "0"
					Pos = ((222.0, 78.0) + (<i> * (-37.0, 0.0)))
					z = 25
					just = [ center center ]
					rgba = <rgba>
					noshadow
				}
				<id> ::SetTags intial_pos = ((222.0, 78.0) + (<i> * (-37.0, 0.0)))
			endif
			<i> = (<i> + 1)
		repeat 4
	endif
endscript

script #"0x80dbe5eb"
endscript

script Song_Intro_Highway_Up_SFX_Waiting
	printingtext = ($current_intro.highway_move_time)
	waitTime = (($current_intro.highway_move_time / 1000.0) - 2.0)
	if (<waitTime> < 0)
		waitTime = 0
	endif
	Wait <waitTime> Seconds
	SoundEvent \{ event = Song_Intro_Highway_Up }
endscript
Song_Win_Delay = 0.5
pulsate_star_power_bulb = $EmptyScript
pulsate_big_glow = $EmptyScript
pulsate_all_star_power_bulbs = $EmptyScript

// i hate this so much
hitnoteids_greenp1 = #"0x00000000"
hitnoteids_redp1 = #"0x00000000"
hitnoteids_yellowp1 = #"0x00000000"
hitnoteids_bluep1 = #"0x00000000"
hitnoteids_orangep1 = #"0x00000000"
hitfxids_greenp1 = #"0x00000000"
hitfxids_redp1 = #"0x00000000"
hitfxids_yellowp1 = #"0x00000000"
hitfxids_bluep1 = #"0x00000000"
hitfxids_orangep1 = #"0x00000000"
hitnoteids_greenp2 = #"0x00000000"
hitnoteids_redp2 = #"0x00000000"
hitnoteids_yellowp2 = #"0x00000000"
hitnoteids_bluep2 = #"0x00000000"
hitnoteids_orangep2 = #"0x00000000"
hitfxids_greenp2 = #"0x00000000"
hitfxids_redp2 = #"0x00000000"
hitfxids_yellowp2 = #"0x00000000"
hitfxids_bluep2 = #"0x00000000"
hitfxids_orangep2 = #"0x00000000"

fx_color_strings = {
	// why are these ids messed up
	// this is just how they looked in debugger / params
	// maybe code typo???? because it skips red and blue from index 2
	#"0x00430a6f" = 'green'
	#"0x0042b14e" = 'red'
	HitNote_Green = 'yellow'
	HitNote_Yellow = 'blue'
	HitNote_Orange = 'orange'
}

script GuitarEvent_UnnecessaryNote
	Guitar_Wrong_Note_Sound_Logic <...>
	if NOT ($is_network_game & ($<player_status>.Player = 2))
		Change StructureName = <player_status> guitar_volume = 0
		UpdateGuitarVolume
	endif
	CrowdDecrease player_status = <player_status>
	if ($show_play_log = 1)
		if (<array_entry> > 0)
			<songtime> = (<songtime> - ($check_time_early * 1000.0))
			next_note = ($<song>[<array_entry>][0])
			prev_note = ($<song>[(<array_entry> -1)][0])
			next_time = (<next_note> - <songtime>)
			prev_time = (<songtime> - <prev_note>)
			if (<prev_time> < ($check_time_late * 1000.0))
				<prev_time> = 1000000.0
			endif
			pad <next_time> count = 8 pad = '.'
			next_time_str = <pad>
			pad <next_note> count = 8 pad = '.'
			next_note = <pad>
			pad <prev_time> count = 8 pad = '.'
			prev_time_str = <pad>
			pad <prev_note> count = 8 pad = '.'
			prev_note = <pad>
			if (<next_time> < <prev_time>)
				<next_time> = (0 - <next_time>)
				output_log_text '%p - ME: %n (%t)' p = <player> n = <next_time_str> t = <next_note> Color = red
			else
				output_log_text '%p - ML: %n (%t)' p = <player> n = <prev_time_str> t = <prev_note> Color = darkred
			endif
		endif
	endif
	GetHeldPattern controller = ($<player_status>.controller) player_status = <player_status>
	i = 0
	AddParams \{msb = 1 i = 0}
	begin
		if (<msb> & <hold_pattern>)
			spawnscriptnow push_button_up params = { player_text = ($<player_status>.text) (4 - <i>) high = $button_up_higher }
			break
		endif
		msb = (<msb> * 16)
		Increment \{i}
	repeat 5
endscript

script update_score_fast
	if ($Cheat_PerformanceMode = 1 || $hudless = 1)
		if ($game_mode = training)
			begin
				GetSongTimeMs
				if (<time> > $current_section_array[($current_section_array_entry + 1)].time)
					change current_section_array_entry = ($current_section_array_entry + 1)
				endif
				wait \{1 gameframe}
			repeat
		endif
		return
	endif
	player_text = ($<player_status>.text)
	button_up_models = ($button_up_models)
	gem_colors = ($gem_colors)
	gem_colors_text = ($gem_colors_text)
	prefix = 'NowBar_Neck'
	<last_pattern> = -1
	UpdateScoreFastInit player_status = <player_status>
	begin
		GetSongTimeMs
		UpdateScoreFastPerFrame player_status = <player_status> time = <time>
		GetHeldPattern controller = ($<player_status>.controller) player_status = <player_status>
		if NOT (<last_pattern> = <hold_pattern>)
			<last_pattern> = <hold_pattern>
			check_button = 65536
			i = 0
			begin
				FastFormatCrc (<button_up_models>.(<gem_colors>[<i>]).name) a = '_neck' b = <player_text> out = neck
				if (<last_pattern> & <check_button>)
					SysTex (<prefix> + '_' + (<gem_colors_text>[<i>]))
				else
					SysTex (<prefix> + '01')
				endif
				if ScreenElementExists id = <neck>
					SetScreenElementProps id = <neck> material = <sys_tex>
				endif
				check_button = (<check_button> / 16)
				Increment \{i}
			repeat 5
		endif
		wait \{1 gameframe}
	repeat
endscript

// gh2_notefx_stupifying.qbs
script hit_note_fx
	if ($disable_particles > 1)
		return
	endif
	NoteFX <...>
	b = ($fx_color_strings.<name>)
	FastFormatCrc hitnoteids_ a = <b> b = <player_text> out = a
	FastFormatCrc hitfxids_ a = <b> b = <player_text> out = c
	change globalname = <a> newvalue = <fx_id>
	change globalname = <c> newvalue = <particle_id>
	
	i = 0
	begin
		if (<b> = $gem_colors_text[<i>])
			spawnscriptnow push_button_up params = { player_text = <player_text> <i> }
		endif
		Increment \{i}
	repeat 5
	
	if ($disable_particles = 0)
		Wait 100 #"0x8d07dc15"
		Destroy2DParticleSystem id = <particle_id> kill_when_empty
	endif
	if ($disable_particles = 1)
		Destroy2DParticleSystem id = <particle_id>
		Wait 100 #"0x8d07dc15"
	endif
	if ($disable_particles < 2)
		Wait 167 #"0x8d07dc15"
		if (ScreenElementExists id = <fx_id>)
			DestroyScreenElement id = <fx_id>
		endif
	endif
endscript

// gh2_hitnote_stupifying.qbs
script GuitarEvent_HitNotes
	if ($enable_solos = 1)
		if NOT (($<player_status>.highway_layout) = solo_highway)
			player_text = ($<player_status>.text)
			if (<player_text> = 'p1')
				Player = 1
				Change note_index_p1 = <array_entry>
			elseif (<player_text> = 'p2')
				Player = 2
				Change note_index_p2 = <array_entry>
			endif
			set_solo_hit_buffer Player = <Player>
			ExtendCrc solo_active_ <player_text> out = sa_p
			update_text = 1
			if ($<sa_p> = 1)
				if (<Player> = 1)
					if ($last_solo_index_p1 < ($last_solo_total_p1 + 1))
						num = ($last_solo_hits_p1 + 1)
						Change last_solo_hits_p1 = <num>
					else
						update_text = 0
					endif
				elseif (<Player> = 2)
					if ($last_solo_index_p2 < ($last_solo_total_p2 + 1))
						num = ($last_solo_hits_p2 + 1)
						Change last_solo_hits_p2 = <num>
					else
						update_text = 0
					endif
				endif
				if (<update_text> = 1)
					solo_ui_update Player = <Player>
				endif
			endif
		endif
	endif
	if (GuitarEvent_HitNotes_CFunc)
		UpdateGuitarVolume
	endif
	if ($show_play_log = 1)
		if ($show_play_log = 1)
			off_note = (0.0 - (<off_note> - $time_input_offset))
			note_time = ($<song>[<array_entry>][0])
			pad <off_note> count = 8 pad = '.'
			off_note_str = <pad>
			pad <note_time> count = 8 pad = '.'
			if (<off_note> < 0)
				output_log_text '%p - HE: %n (%t)' p = <player> n = <off_note_str> t = <pad> Color = green
			else
				output_log_text '%p - HL: %n (%t)' p = <player> n = <off_note_str> t = <pad> Color = darkgreen
			endif
		endif
	endif
	if ($FC_MODE = 1)
		Change StructureName = <player_status> current_health = 0.000000000000001
	endif
	if (GotParam open)
		if (<whammy_length> > 0)
			ExtendCrc open_sustain_fx ($<player_status>.text) out = scr_name
		endif
		spawnscriptnow Open_NoteFX id = <scr_name> params = {
			Player = <Player> player_status = <player_status> length = <whammy_length>
		}
	endif
	
	// terminally ill
	i = 0
	begin
		c = ($gem_colors_text[<i>])
		FastFormatCrc a = hitnoteids_ b = <c> c = <player_text> out = a
		FastFormatCrc a = hitfxids_ b = <c> c = <player_text> out = b
		if NOT ($<a> = #"0x00000000")
			if ScreenElementExists id = ($<a>)
				DestroyScreenElement id = ($<a>)
			endif
		endif
		if NOT ($<b> = #"0x00000000")
			Destroy2DParticleSystem id = ($<b>)
		endif
		Increment \{i}
	repeat 5
	
endscript

script intro_buttonup_ripple
	//EnableInput OFF controller = ($<player_status>.controller)
	begin
		GetSongTimeMs
		if ($current_intro.button_ripple_start_time + $current_starttime < <time>)
			break
		endif
		wait \{1 gameframe}
	repeat
	if ($current_intro.button_ripple_per_button_time = 0)
		return
	endif
	GetArraySize \{$gem_colors}
	SoundEvent \{event = Notes_Ripple_Up_SFX}
	player_text = ($<player_status>.text)
	//ExtendCrc button_up_pixel_array ($<player_status>.text)out = pixel_array
	buttonup_count = 0
	begin
		wait ($current_intro.button_ripple_per_button_time / 1000.0)seconds
		array_count = 0
		begin // wtf even is this
			Color = ($gem_colors [<array_count>])
			if (<array_count> = <buttonup_count>)
				//SetArrayElement ArrayName = <pixel_array> GlobalArray index = <array_count> NewValue = $button_up_pixels
				spawnscriptnow push_button_up params = { player_text = <player_text> <array_count> high = $button_up_higher }
			endif
			array_count = (<array_count> + 1)
		repeat <array_Size>
		buttonup_count = (<buttonup_count> + 1)
	repeat (<array_Size> + 1)
	EnableInput controller = ($<player_status>.controller)
	wait ($current_intro.button_ripple_per_button_time / 500.0) seconds
	i = 0
	begin
		spawnscriptnow push_button_up params = { player_text = <player_text> <i> high = $button_up_higher }
		Increment \{i}
	repeat 5
endscript
script push_button_up \{scale = 1.0 high = $button_up_pixels}
	ExtendCrc button_up_pixel_array <player_text> out = array
	time = 0.000055
	begin
		ln (<time> / 0.06)
		SetArrayElement ArrayName = <array> GlobalArray index = <#"0x00000000"> NewValue = ((7.0 + <ln>) / 7 * <high>)
		if (<time> > 0.06)
			break
		endif
		GetDeltaTime
		time = (<time> + <delta_time>)
		Wait \{1 gameframe}
	repeat
endscript

neck_sprite_size = 16
neck_lip_add = 16
neck_lip_base = 6
button_up_pixels = 12.0
button_up_higher = 30.0
button_sink_time = 0.1

nowbar_scale_x1 = 0.856
sidebar_normal1 = [ 255 255 255 255 ]
sidebar_starpower0 = [ 128 192 255 255 ]
sidebar_starpower1 = $color_white
sidebar_dying0 = $color_white
sidebar_dying1 = [255 80 80 255]
GH2_scorelight_pos0 = (53.0, 154.0)
GH2_scorelight_rot0 = -38.0
GH2_scorelight_scale0 = 0.62
GH2_scorelight_pos1 = (85.0, 128.0)
GH2_scorelight_rot1 = -23.0
GH2_scorelight_scale1 = 0.57
GH2_scorelight_pos2 = (120.0, 113.0)
GH2_scorelight_rot2 = -7.0
GH2_scorelight_scale2 = 0.53
GH2_scorelight_pos3 = (156.0, 110.0)
GH2_scorelight_rot3 = 10.0
GH2_scorelight_scale3 = 0.49
GH2_scorelight_pos4 = (190.0, 117.0)
GH2_scorelight_rot4 = 37.0
GH2_scorelight_scale4 = 0.47
career_hud_2d_elements = {
	offscreen_rock_pos = (2000.0, 610.0)
	offscreen_score_pos = (-500.0, 560.0)
	rock_pos = (1260.0, 692.0)
	score_pos = (300.0, 650.0)
	counter_pos = (250.0, 910.0)
	offscreen_rock_pos_p1 = (-500.0, 100.0)
	offscreen_score_pos_p1 = (-500.0, 40.0)
	rock_pos_p1 = (550.0, 100.0)
	score_pos_p1 = (250.0, 40.0)
	counter_pos_p1 = (-2000.0, 200.0)
	offscreen_rock_pos_p2 = (2000.0, 100.0)
	offscreen_score_pos_p2 = (2000.0, 40.0)
	rock_pos_p2 = (1200.0, 100.0)
	score_pos_p2 = (900.0, 40.0)
	counter_pos_p2 = (-2000.0, 200.0)
	offscreen_note_streak_bar_off = (0.0, 800.0)
	#"0x936bb5fe" = (0.0, -7.0)
	Scale = 0.7
	small_bulb_scale = 0.7
	big_bulb_scale = 1.0
	z = 0
	score_frame_width = 200.0
	offscreen_gamertag_pos = (0.0, -400.0)
	final_gamertag_pos = (0.0, 0.0)
	elements = [
		{ parent_container element_id = #"0xa90fc148" pos_type = #"0x936bb5fe" }
		{
			element_id = #"0x99dd87cc"
			element_parent = #"0xa90fc148"
			texture = #"0x24535078"
			pos_off = (0.0, 0.0)
			dims = (1920.0, 1130.0)
			rgba = $#"0x902ecc17"
			zoff = -2147483648
		}
		{ parent_container element_id = HUD2D_rock_container pos_type = offscreen_rock_pos }
		{
			element_id = HUD2D_rock_glow
			element_parent = HUD2D_rock_container
			texture = Char_Select_Hilite1
			pos_off = (-50.0, -100.0)
			dims = (350.0, 350.0)
			rgba = [ 95 205 255 255 ]
			alpha = 0
			zoff = -10
		}
		{
			element_id = HUD2D_rock_body
			element_parent = HUD2D_rock_container
			texture = hud_rock_body
			pos_off = (0.0, -50.0)
			Scale = 1.4
			zoff = 22
		}
		{
			element_id = HUD2D_rock_BG_green
			element_parent = HUD2D_rock_body
			texture = hud_rock_bg_green
			pos_off = (0.0, 0.0)
			zoff = 16
		}
		{
			element_id = HUD2D_rock_BG_red
			element_parent = HUD2D_rock_body
			texture = hud_rock_bg_red
			pos_off = (0.0, 0.0)
			zoff = 14
		}
		{
			element_id = HUD2D_rock_BG_yellow
			element_parent = HUD2D_rock_body
			texture = hud_rock_bg_yellow
			pos_off = (0.0, 0.0)
			zoff = 15
		}
		{
			element_id = HUD2D_rock_lights_all
			element_parent = HUD2D_rock_body
			texture = hud_rock_lights_all
			pos_off = (0.0, 0.0)
			zoff = 17
		}
		{
			element_id = HUD2D_rock_lights_green
			element_parent = HUD2D_rock_body
			texture = hud_rock_lights_green
			pos_off = (0.0, 0.0)
			zoff = 18
			just = [ left top ]
			alpha = 0
		}
		{
			element_id = HUD2D_rock_lights_red
			element_parent = HUD2D_rock_body
			texture = hud_rock_lights_red
			pos_off = (0.0, 0.0)
			zoff = 18
			just = [ left top ]
			alpha = 0
		}
		{
			element_id = HUD2D_rock_lights_yellow
			element_parent = HUD2D_rock_body
			texture = hud_rock_lights_yellow
			pos_off = (128.0, 0.0)
			zoff = 18
			just = [ center top ]
			alpha = 0
		}
		{
			element_id = HUD2D_rock_needle
			element_parent = HUD2D_rock_body
			texture = hud_rock_needle
			pos_off = (121.5, 210.0)
			zoff = 19
			just = [ 0.5 1.0 ]
		}
		{
			element_id = #"0x87004517"
			element_parent = HUD2D_rock_body
			texture = #"0x03ef05a1"
			pos_off = (0.0, 0.0)
			zoff = $#"0x67cf1f5d"
		}
		{
			element_id = #"0x5b77b0ef"
			element_parent = HUD2D_rock_body
			texture = hud_rock_lights_all
			pos_off = (0.0, 0.0)
			zoff = $#"0xdd6ab3d6"
		}
		{
			parent_container
			element_id = HUD2D_bulb_container_1
			element_parent = HUD2D_rock_body
			pos_off = (76.30000305175781, 32.0)
			rot = 90.0
		}
		{
			element_id = HUD2D_rock_tube_1
			element_parent = HUD2D_bulb_container_1
			texture = None
			pos_off = (0.0, 0.0)
			element_dims = (16.0, 0.0)
			small_bulb
			zoff = 24
			just = [ center center ]
			container
			tube = {
				texture = hud_rock_tube_glow_fill_b
				star_texture = hud_rock_tube_glow_fill_b
				element_dims = (64.0, 200.0)
				pos_off = (0.0, 40.0)
				zoff = 24
				alpha = 1
			}
			full = { texture = None star_texture = None zoff = 0 alpha = 0 }
		}
		{
			parent_container
			element_id = HUD2D_bulb_container_2
			element_parent = HUD2D_rock_body
			pos_off = (101.9000015258789, 32.0)
			rot = 89.83
		}
		{
			element_id = HUD2D_rock_tube_2
			element_parent = HUD2D_bulb_container_2
			texture = None
			pos_off = (0.0, 0.0)
			element_dims = (64.0, 128.0)
			small_bulb
			zoff = 25
			just = [ center center ]
			container
			tube = {
				texture = hud_rock_tube_glow_fill_b
				star_texture = hud_rock_tube_glow_fill_b
				element_dims = (64.0, 16.0)
				pos_off = (0.0, 40.0)
				zoff = 25.0
				alpha = 1
			}
			full = { texture = None star_texture = None zoff = 0.0 alpha = 0 }
		}
		{
			parent_container
			element_id = HUD2D_bulb_container_3
			element_parent = HUD2D_rock_body
			pos_off = (127.4000015258789, 32.0)
			rot = 89.83
		}
		{
			element_id = HUD2D_rock_tube_3
			element_parent = HUD2D_bulb_container_3
			texture = None
			pos_off = (0.0, 0.0)
			element_dims = (64.0, 128.0)
			small_bulb
			zoff = 0
			just = [ center center ]
			container
			tube = {
				texture = hud_rock_tube_glow_fill_b
				star_texture = hud_rock_tube_glow_fill_b
				element_dims = (64.0, 16.0)
				pos_off = (0.0, 40.0)
				zoff = 26.0
				alpha = 1
			}
			full = { texture = None star_texture = None zoff = 0.2 alpha = 0 }
		}
		{
			parent_container
			element_id = HUD2D_bulb_container_4
			element_parent = HUD2D_rock_body
			pos_off = (152.89999389648438, 32.0)
			rot = 89.84
		}
		{
			element_id = HUD2D_rock_tube_4
			element_parent = HUD2D_bulb_container_4
			texture = None
			pos_off = (0.0, 0.0)
			initial_pos = (0.0, 0.0)
			element_dims = (64.0, 128.0)
			big_bulb
			zoff = 0
			just = [ center center ]
			container
			tube = {
				texture = hud_rock_tube_glow_fill_b
				star_texture = hud_rock_tube_glow_fill_b
				element_dims = (64.0, 16.0)
				pos_off = (0.0, 40.0)
				zoff = 27.0
				alpha = 1
			}
			full = { texture = None star_texture = None zoff = 0.2 alpha = 0 }
		}
		{
			parent_container
			element_id = HUD2D_bulb_container_5
			element_parent = HUD2D_rock_body
			pos_off = (178.6999969482422, 32.0)
			rot = 89.85
		}
		{
			element_id = HUD2D_rock_tube_5
			element_parent = HUD2D_bulb_container_5
			texture = None
			pos_off = (0.0, 0.0)
			initial_pos = (0.0, 0.0)
			element_dims = (64.0, 128.0)
			big_bulb
			zoff = 0
			just = [ center center ]
			container
			tube = {
				texture = hud_rock_tube_glow_fill_b
				star_texture = hud_rock_tube_glow_fill_b
				element_dims = (64.0, 16.0)
				pos_off = (0.0, 40.0)
				zoff = 28.0
				alpha = 1
			}
			full = { texture = None star_texture = None zoff = 0.2 alpha = 0 }
		}
		{
			parent_container
			element_id = HUD2D_bulb_container_6
			element_parent = HUD2D_rock_body
			pos_off = (204.3000030517578, 32.0)
			rot = 89.85
		}
		{
			element_id = HUD2D_rock_tube_6
			element_parent = HUD2D_bulb_container_6
			texture = None
			pos_off = (0.0, 0.0)
			initial_pos = (0.0, 0.0)
			element_dims = (64.0, 128.0)
			big_bulb
			zoff = 0
			just = [ center center ]
			container
			tube = {
				texture = hud_rock_tube_glow_fill_b
				star_texture = hud_rock_tube_glow_fill_b
				element_dims = (64.0, 16.0)
				pos_off = (0.0, 40.0)
				zoff = 29.0
				alpha = 1
			}
			full = { texture = None star_texture = None zoff = 0.2 alpha = 0 }
		}
		{ parent_container element_id = HUD2D_score_container pos_type = offscreen_score_pos }
		{
			element_id = HUD2D_score_body
			element_parent = HUD2D_score_container
			texture = hud_score_body
			pos_type = score_pos
			pos_off = (-90.0, 20.0)
			Scale = 1.4
			zoff = 5
		}
		{
			parent_container
			element_id = HUD2D_note_container
			pos_type = counter_pos
			note_streak_bar
			pos_off = (0.0, 0.0)
		}
		{
			element_id = HUD2D_counter_body
			element_parent = HUD2D_note_container
			texture = hud_counter_body
			pos_off = (0.0, 0.0)
			zoff = 9
		}
		{
			element_id = hud_counter_drum
			element_parent = HUD2D_note_container
			texture = hud_counter_drum
			pos_off = (4.0, 40.0)
			zoff = 8
		}
		{
			element_id = HUD2D_counter_drum_icon
			element_parent = HUD2D_note_container
			texture = hud_counter_drum_icon
			pos_off = (44.0, 40.0)
			zoff = 26
		}
		{
			element_id = HUD2D_score_light_unlit_1
			element_parent = HUD2D_score_body
			texture = hud_score_light_0
			pos_off = $GH2_scorelight_pos0
			Scale = $GH2_scorelight_scale0
			rot = $GH2_scorelight_rot0
			zoff = 5.1
		}
		{
			element_id = HUD2D_score_light_unlit_2
			element_parent = HUD2D_score_body
			texture = hud_score_light_0
			pos_off = $GH2_scorelight_pos1
			Scale = $GH2_scorelight_scale1
			rot = $GH2_scorelight_rot1
			zoff = 5.1
		}
		{
			element_id = HUD2D_score_light_unlit_3
			element_parent = HUD2D_score_body
			texture = hud_score_light_0
			pos_off = $GH2_scorelight_pos2
			Scale = $GH2_scorelight_scale2
			rot = $GH2_scorelight_rot2
			zoff = 5.1
		}
		{
			element_id = HUD2D_score_light_unlit_4
			element_parent = HUD2D_score_body
			texture = hud_score_light_0
			pos_off = $GH2_scorelight_pos3
			Scale = $GH2_scorelight_scale3
			rot = $GH2_scorelight_rot3
			zoff = 5.1
		}
		{
			element_id = HUD2D_score_light_unlit_5
			element_parent = HUD2D_score_body
			texture = hud_score_light_0
			pos_off = $GH2_scorelight_pos4
			Scale = $GH2_scorelight_scale4
			rot = $GH2_scorelight_rot4
			zoff = 5.1
		}
		{
			element_id = HUD2D_score_light_halflit_1
			element_parent = HUD2D_score_body
			texture = hud_score_light_1
			pos_off = $GH2_scorelight_pos0
			Scale = $GH2_scorelight_scale0
			rot = $GH2_scorelight_rot0
			zoff = 5.2
			alpha = 0
		}
		{
			element_id = HUD2D_score_light_halflit_2
			element_parent = HUD2D_score_body
			texture = hud_score_light_1
			pos_off = $GH2_scorelight_pos1
			Scale = $GH2_scorelight_scale1
			rot = $GH2_scorelight_rot1
			zoff = 5.2
			alpha = 0
		}
		{
			element_id = HUD2D_score_light_halflit_3
			element_parent = HUD2D_score_body
			texture = hud_score_light_1
			pos_off = $GH2_scorelight_pos2
			Scale = $GH2_scorelight_scale2
			rot = $GH2_scorelight_rot2
			zoff = 5.2
			alpha = 0
		}
		{
			element_id = HUD2D_score_light_halflit_4
			element_parent = HUD2D_score_body
			texture = hud_score_light_1
			pos_off = $GH2_scorelight_pos3
			Scale = $GH2_scorelight_scale3
			rot = $GH2_scorelight_rot3
			zoff = 5.2
			alpha = 0
		}
		{
			element_id = HUD2D_score_light_halflit_5
			element_parent = HUD2D_score_body
			texture = hud_score_light_1
			pos_off = $GH2_scorelight_pos4
			Scale = $GH2_scorelight_scale4
			rot = $GH2_scorelight_rot4
			zoff = 5.2
			alpha = 0
		}
		{
			element_id = HUD2D_score_light_allwaylit_1
			element_parent = HUD2D_score_body
			texture = hud_score_light_2
			pos_off = $GH2_scorelight_pos0
			Scale = $GH2_scorelight_scale0
			rot = $GH2_scorelight_rot0
			zoff = 5.3
			alpha = 0
		}
		{
			element_id = HUD2D_score_light_allwaylit_2
			element_parent = HUD2D_score_body
			texture = hud_score_light_2
			pos_off = $GH2_scorelight_pos1
			Scale = $GH2_scorelight_scale1
			rot = $GH2_scorelight_rot1
			zoff = 5.3
			alpha = 0
		}
		{
			element_id = HUD2D_score_light_allwaylit_3
			element_parent = HUD2D_score_body
			texture = hud_score_light_2
			pos_off = $GH2_scorelight_pos2
			Scale = $GH2_scorelight_scale2
			rot = $GH2_scorelight_rot2
			zoff = 5.3
			alpha = 0
		}
		{
			element_id = HUD2D_score_light_allwaylit_4
			element_parent = HUD2D_score_body
			texture = hud_score_light_2
			pos_off = $GH2_scorelight_pos3
			Scale = $GH2_scorelight_scale3
			rot = $GH2_scorelight_rot3
			zoff = 5.3
			alpha = 0
		}
		{
			element_id = HUD2D_score_light_allwaylit_5
			element_parent = HUD2D_score_body
			texture = hud_score_light_2
			pos_off = $GH2_scorelight_pos4
			Scale = $GH2_scorelight_scale4
			rot = $GH2_scorelight_rot4
			zoff = 5.3
			alpha = 0
		}
		{
			element_id = HUD2D_score_nixie_1a
			element_parent = HUD2D_score_body
			texture = hud_score_nixie_1a
			pos_off = (88.0, 125.0)
			Scale = 0.75
			zoff = 4
			alpha = 0
		}
		{
			element_id = HUD2D_score_nixie_2a
			element_parent = HUD2D_score_body
			texture = hud_score_nixie_2a
			pos_off = (88.0, 125.0)
			Scale = 0.75
			zoff = 4
			alpha = 0
		}
		{
			element_id = HUD2D_score_nixie_2b
			element_parent = HUD2D_score_body
			texture = hud_score_nixie_2b
			pos_off = (88.0, 125.0)
			Scale = 0.75
			zoff = 4
			alpha = 0
		}
		{
			element_id = HUD2D_score_nixie_3a
			element_parent = HUD2D_score_body
			texture = hud_score_nixie_3a
			pos_off = (88.0, 125.0)
			Scale = 0.75
			zoff = 4
			alpha = 0
		}
		{
			element_id = HUD2D_score_nixie_4a
			element_parent = HUD2D_score_body
			texture = hud_score_nixie_4a
			pos_off = (88.0, 125.0)
			Scale = 0.75
			zoff = 4
			alpha = 0
		}
		{
			element_id = HUD2D_score_nixie_4b
			element_parent = HUD2D_score_body
			texture = hud_score_nixie_4b
			pos_off = (88.0, 125.0)
			Scale = 0.75
			zoff = 4
			alpha = 0
		}
		{
			element_id = HUD2D_score_nixie_6b
			element_parent = HUD2D_score_body
			texture = hud_score_nixie_6b
			pos_off = (88.0, 125.0)
			Scale = 0.75
			zoff = 4
			alpha = 0
		}
		{
			element_id = HUD2D_score_nixie_8b
			element_parent = HUD2D_score_body
			texture = hud_score_nixie_8b
			pos_off = (88.0, 125.0)
			Scale = 0.75
			zoff = 4
			alpha = 0
		}
		{
			element_id = HUD2D_score_flash
			element_parent = HUD2D_score_container
			texture = hud_score_flash
			just = [ center center ]
			pos_off = (128.0, 128.0)
			zoff = 20
			alpha = 0
		}
	]
}
ui_sfx_scroll_container = {
	Command = PlaySound
	Randomness = RandomNoRepeatType
	Sounds = {
		Sound1 = { scroll }
		Sound2 = { scroll2 }
		Sound3 = { scroll3 }
	}
}
Star_Power_Awarded_SFX_container = {
	Command = PlaySound
	Randomness = RandomNoRepeatType
	Sounds = {
		Sound1 = {
			sp_awarded1
			vol = 90
			pan1x = -0.5
			pan1y = 0.866025
			pan2x = 0.5
			pan2y = 0.866025
		}
		Sound2 = {
			sp_awarded2
			vol = 90
			pan1x = -0.5
			pan1y = 0.866025
			pan2x = 0.5
			pan2y = 0.866025
		}
		Sound3 = {
			sp_awarded3
			vol = 90
			pan1x = -0.5
			pan1y = 0.866025
			pan2x = 0.5
			pan2y = 0.866025
		}
		Sound4 = {
			sp_awarded4
			vol = 90
			pan1x = -0.5
			pan1y = 0.866025
			pan2x = 0.5
			pan2y = 0.866025
		}
	}
}
Star_Power_Awarded_SFX_P1_container = {
	Command = PlaySound
	Randomness = RandomNoRepeatType
	Sounds = {
		Sound1 = {
			sp_awarded1
			vol = 80
			pan1x = -0.762
			pan1y = 0.647
			pan2x = -0.448
			pan2y = 0.894
		}
		Sound2 = {
			sp_awarded2
			vol = 80
			pan1x = -0.762
			pan1y = 0.647
			pan2x = -0.448
			pan2y = 0.894
		}
		Sound3 = {
			sp_awarded3
			vol = 80
			pan1x = -0.762
			pan1y = 0.647
			pan2x = -0.448
			pan2y = 0.894
		}
		Sound4 = {
			sp_awarded4
			vol = 80
			pan1x = -0.762
			pan1y = 0.647
			pan2x = -0.448
			pan2y = 0.894
		}
	}
}
Star_Power_Awarded_SFX_P2_container = {
	Command = PlaySound
	Randomness = RandomNoRepeatType
	Sounds = {
		Sound1 = {
			sp_awarded1
			vol = 80
			pan1x = 0.47
			pan1y = 0.883
			pan2x = 0.728
			pan2y = 0.685
		}
		Sound2 = {
			sp_awarded2
			vol = 80
			pan1x = 0.47
			pan1y = 0.883
			pan2x = 0.728
			pan2y = 0.685
		}
		Sound3 = {
			sp_awarded3
			vol = 80
			pan1x = 0.47
			pan1y = 0.883
			pan2x = 0.728
			pan2y = 0.685
		}
		Sound4 = {
			sp_awarded4
			vol = 80
			pan1x = 0.47
			pan1y = 0.883
			pan2x = 0.728
			pan2y = 0.685
		}
	}
}
Battle_Power_Awarded_SFX_P1_container = {
	Command = PlaySound
	Randomness = RandomNoRepeatType
	Sounds = {
		Sound1 = {
			sp_awarded1
			vol = 90
			pan1x = -0.762
			pan1y = 0.647
			pan2x = -0.448
			pan2y = 0.894
		}
		Sound2 = {
			sp_awarded2
			vol = 90
			pan1x = -0.762
			pan1y = 0.647
			pan2x = -0.448
			pan2y = 0.894
		}
		Sound3 = {
			sp_awarded3
			vol = 90
			pan1x = -0.762
			pan1y = 0.647
			pan2x = -0.448
			pan2y = 0.894
		}
		Sound4 = {
			sp_awarded4
			vol = 90
			pan1x = -0.762
			pan1y = 0.647
			pan2x = -0.448
			pan2y = 0.894
		}
	}
}
Battle_Power_Awarded_SFX_P2_container = {
	Command = PlaySound
	Randomness = RandomNoRepeatType
	Sounds = {
		Sound1 = {
			sp_awarded1
			vol = 80
			pan1x = 0.47
			pan1y = 0.883
			pan2x = 0.728
			pan2y = 0.685
		}
		Sound2 = {
			sp_awarded2
			vol = 80
			pan1x = 0.47
			pan1y = 0.883
			pan2x = 0.728
			pan2y = 0.685
		}
		Sound3 = {
			sp_awarded3
			vol = 80
			pan1x = 0.47
			pan1y = 0.883
			pan2x = 0.728
			pan2y = 0.685
		}
		Sound4 = {
			sp_awarded4
			vol = 80
			pan1x = 0.47
			pan1y = 0.883
			pan2x = 0.728
			pan2y = 0.685
		}
	}
}
