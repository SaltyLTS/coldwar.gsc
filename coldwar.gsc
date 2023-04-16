#include common_scripts/utility;
#include maps/mp/_demo;
#include maps/mp/_utility;
#include maps/mp/_visionset_mgr;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/gametypes_zm/_weapons;
#include maps/mp/gametypes_zm/_zm_gametype;
#include maps/mp/zombies/_zm;
#include maps/mp/zombies/_zm_ai_basic;
#include maps/mp/zombies/_zm_ai_dogs;
#include maps/mp/zombies/_zm_audio;
#include maps/mp/zombies/_zm_audio_announcer;
#include maps/mp/zombies/_zm_blockers;
#include maps/mp/zombies/_zm_bot;
#include maps/mp/zombies/_zm_buildables;
#include maps/mp/zombies/_zm_clone;
#include maps/mp/zombies/_zm_devgui;
#include maps/mp/zombies/_zm_equipment;
#include maps/mp/zombies/_zm_ffotd;
#include maps/mp/zombies/_zm_game_module;
#include maps/mp/zombies/_zm_gump;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/zombies/_zm_magicbox;
#include maps/mp/zombies/_zm_melee_weapon;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_pers_upgrades;
#include maps/mp/zombies/_zm_pers_upgrades_system;
#include maps/mp/zombies/_zm_pers_upgrades_functions;
#include maps/mp/zombies/_zm_playerhealth;
#include maps/mp/zombies/_zm_powerups;
#include maps/mp/zombies/_zm_power;
#include maps/mp/zombies/_zm_score;
#include maps/mp/zombies/_zm_sidequests;
#include maps/mp/zombies/_zm_spawner;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/zombies/_zm_timer;
#include maps/mp/zombies/_zm_tombstone;
#include maps/mp/zombies/_zm_traps;
#include maps/mp/zombies/_zm_unitrigger;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_zm_zonemgr;

init()
{
	setdvar("player_backSpeedScale", 1);
	setdvar("player_strafeSpeedScale", 1);
	precacheshader("damage_feedback");
	level.zombie_vars["zombie_spawn_delay"] = 0;
	level.perk_purchase_limit = 11;
	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	level endon("end_game");
	self endon("disconnect");
	for(;;)
	{
		self waittill("spawned_player");
			self thread damagehitmarker();
			self thread maxammo();
			self thread drop_weapon();
			self thread sliding();
	}
}

damagehitmarker()
{
    self thread startwaiting();
    self.hitmarker = newdamageindicatorhudelem( self );
    self.hitmarker.horzalign = "center";
    self.hitmarker.vertalign = "middle";
    self.hitmarker.x = -12;
    self.hitmarker.y = -12;
    self.hitmarker.alpha = 0;
    self.hitmarker setshader( "damage_feedback", 24, 48 );
}

startwaiting()
{
    for(;;)
    {
        foreach( zombie in getaiarray( level.zombie_team ) )
        {
            if( !(IsDefined( zombie.waitingfordamage )) )
            {
                zombie thread hitmark();
            }
        }
        wait 0.25;
    }
}

hitmark()
{
    self endon( "killed" );
    self.waitingfordamage = 1;
    for(;;)
    {
        self waittill( "damage", amount, attacker, dir, point, mod );
        attacker.hitmarker.alpha = 0;
        if( isplayer( attacker ) )
        {
            if( isalive( self ) )
            {
                attacker.hitmarker.color = ( 1, 1, 1 );
                attacker.hitmarker.alpha = 1;
                attacker.hitmarker fadeovertime( 1 );
                attacker.hitmarker.alpha = 0;
            }
            else
            {
                attacker.hitmarker.color = ( 1, 0, 0 );
                attacker.hitmarker.alpha = 1;
                attacker.hitmarker fadeovertime( 1 );
                attacker.hitmarker.alpha = 0;
                self notify( "killed" );
            }
        }
    }
}

maxammo()
{
	level endon("end_game");
	self endon("disconnect");
	for(;;) 
	{
		self waittill("zmb_max_ammo");
		weaps = self getweaponslist(1);
		foreach (weap in weaps) 
		{
			self setweaponammoclip(weap, weaponclipsize(weap));
		}
	}
}

drop_weapon() {
    level endon("end_game");
    self endon("disconnect");
    for (;;) {
        if (self meleebuttonpressed()) {
            duration = 0;
            while (self meleebuttonpressed()) {
                duration += 1;
                if (duration == 25) {
                    if (self player_is_in_laststand()) break;
                    weap = self getCurrentWeapon();
                    self dropItem(weap);
                    break;
                }
                wait 0.05;
            }
        }
        wait 0.05;
    }
}

sliding()
{
	level endon("end_game");
	self endon("disconnect");
	for(;;)
	{
		if(self stanceButtonPressed())
		{
			timer += 1;
			if(timer == 3)
			{
				stance = self getstance();
				if(self.player_is_moving == 1 && self isonground())
				{
					if (stance != "crouch" && stance != "prone")
					{
						if(self.is_sliding != 1)
						{
							self setstance( "crouch" );
							self allowstand( 0 );
							self allowcrouch( 1 );
							self allowprone( 0 );
							forward = anglesToForward(self getPlayerAngles());
							self setOrigin(self.origin+(0,0,5));
							self.is_sliding = 1;
							for(i=0; i < 5; i++)
							{
								self setVelocity((forward[0]*450, forward[1]*450,0));
								wait 0.01;
							}
							wait 0.1;
							self.is_sliding = 0;
							self allowstand( 1 );
							self allowcrouch( 1 );
							self allowprone( 1 );
							self setstance("stand");
							wait 0.05;
						}
					}
				}
			}
		}
		else
		{
			timer = 0;
		}
		wait 0.05;
    }
}