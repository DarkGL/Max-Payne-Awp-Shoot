/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <csx>
#include <fakemeta>
#include <xs>
#include <engine>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "DarkGL"

#define CLASS_FLY_CAMERA "maxpayne_fly_camera"
#define FLY_CAMERA_MODEL "models/rshell.mdl"

#define CLASS_FLY_AMMO "maxpayne_fly_ammo"
#define FLY_AMMO_MODEL "models/rshell_big.mdl"

new gMax = 0;

#define IsPlayer(%1) ( (1 <= %1 <= gMax) && is_user_connected(%1) ) 

new pCvarHS,pCvarSpeed,pCvarSpeedSlow;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	pCvarHS  	= 	register_cvar("max_payne_shot_hs","0");
	pCvarSpeed 	= 	register_cvar("max_payne_shot_speed","1000.0")
	pCvarSpeedSlow	=	register_cvar("max_payne_shot_speed_slow","5.0")
	
	gMax 		=	get_maxplayers()
	
	register_touch("*",CLASS_FLY_AMMO,"ammoTouched")
	register_think(CLASS_FLY_AMMO,"ammoThink")
}

public plugin_precache(){
	precache_model(FLY_AMMO_MODEL)
	precache_model(FLY_CAMERA_MODEL);
}

public ammoThink(iEnt){
	if(!pev_valid(iEnt))	return	;
	
	new Float:fOrigin[3],Float:fOld[3],Float:fVec[3],Float:fDist;
	pev(iEnt,pev_origin,fOrigin)
	pev(iEnt,pev_oldorigin,fOld)
	
	fDist = get_distance_f(fOrigin,fOld);
	
	client_print(0,3,"%f | %f | %f | %f | %f",fOld[0],fOld[1],fOld[2],fDist,pev(iEnt,pev_fuser1))
	
	if(pev(iEnt,pev_iuser3) == 0.0){
		if(fDist < 40.0){
			pev(iEnt,pev_velocity,fVec);
			xs_vec_normalize(fVec,fVec)
			xs_vec_mul_scalar(fVec,get_pcvar_float(pCvarSpeedSlow),fVec)
			set_pev(iEnt,pev_velocity,fVec)
		}
		set_pev(iEnt,pev_fuser1,fDist)
	}
	else{
		if(fDist > pev(iEnt,pev_fuser1)){
			new id = pev(iEnt,pev_owner);
			
			attach_view(id,id);
			dllfunc( DLLFunc_ClientUserInfoChanged, id, engfunc( EngFunc_GetInfoKeyBuffer, id ) );
			
			remove_entity(pev(iEnt,pev_iuser3))
			remove_entity(iEnt);
			
			return ;
		}
		else{
			pev(iEnt,pev_velocity,fVec);
			xs_vec_normalize(fVec,fVec)
			xs_vec_mul_scalar(fVec,get_pcvar_float(pCvarSpeedSlow),fVec)
			set_pev(iEnt,pev_velocity,fVec)
			set_pev(iEnt,pev_fuser1,fDist)
		}
	}
	
	set_pev(iEnt,pev_nextthink,get_gametime() + 0.01)
}

public ammoTouched(touched,toucher){
	if(touched == 0){
		new id = pev(toucher,pev_owner);
		
		attach_view(id,id);
		dllfunc( DLLFunc_ClientUserInfoChanged, id, engfunc( EngFunc_GetInfoKeyBuffer, id ) );
		
		remove_entity(pev(toucher,pev_iuser3))
		remove_entity(toucher);
	}
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{	
	if(!is_user_alive(killer) || !IsPlayer(victim) || get_user_team(victim) == get_user_team(killer) || wpnindex != CSW_AWP)	return PLUGIN_CONTINUE;
	
	if(get_pcvar_num(pCvarHS) && hitplace != HIT_HEAD)	return PLUGIN_CONTINUE;
	
	new iEnt = createFlyAmmo(killer,victim);
	set_pev(iEnt,pev_iuser3,createFlyCamera(killer))
	
	return PLUGIN_CONTINUE;
}

createFlyAmmo(iFrom,iTo){
	new iEnt = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	
	if(!pev_valid(iEnt))	return 0;
	
	set_pev(iEnt, pev_classname, CLASS_FLY_AMMO)
	
	new Float:fAngles[3];
	pev(iFrom,pev_angles,fAngles);
	set_pev(iEnt,pev_angles,fAngles);
	
	engfunc(EngFunc_SetModel,iEnt,FLY_AMMO_MODEL)
	engfunc(EngFunc_SetSize, iEnt, {-2.0, -2.0, -2.0}, {2.0, 2.0, 2.0})
	
	new Float:fOrigin[3],Float:fOfs[3]
	pev(iFrom,pev_origin,fOrigin)
	pev(iFrom,pev_view_ofs,fOfs)
	xs_vec_add(fOfs,fOrigin,fOrigin)
	
	engfunc(EngFunc_SetOrigin, iEnt, fOrigin)
	
	set_pev(iEnt, pev_solid, SOLID_TRIGGER)
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	set_pev(iEnt, pev_owner,iFrom)
	set_pev(iEnt, pev_iuser4,iTo)
	set_pev(iEnt,pev_iuser3,0)
	set_pev(iEnt,pev_oldorigin,fOrigin);
	
	new Float:fVeloc[3];
	pev(iFrom,pev_v_angle,fAngles);
	angle_vector(fAngles,ANGLEVECTOR_FORWARD,fAngles);
	xs_vec_normalize(fAngles,fAngles);
	xs_vec_mul_scalar(fAngles,get_pcvar_float(pCvarSpeed),fVeloc)
	set_pev(iEnt,pev_velocity,fVeloc)
	
	set_pev(iEnt,pev_nextthink,get_gametime() + 0.01)
	
	return iEnt;
}

createFlyCamera(iPlayer){
	new iEnt = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	
	if(!pev_valid(iEnt))	return 0;
	
	dllfunc(DLLFunc_Spawn, iEnt)
	
	set_pev(iEnt, pev_classname, CLASS_FLY_CAMERA)
	
	new Float:fAngles[3],Float:fAngles2[3]
	pev(iPlayer,pev_angles,fAngles);
	set_pev(iEnt,pev_angles,fAngles);
	
	engfunc(EngFunc_SetModel,iEnt,FLY_CAMERA_MODEL)
	engfunc(EngFunc_SetSize, iEnt, {-2.0, -2.0, 2.0}, {2.0, 2.0, 2.0})
	
	new Float:fOrigin[3],Float:fOfs[3]
	pev(iPlayer,pev_origin,fOrigin)
	pev(iPlayer,pev_view_ofs,fOfs)
	
	xs_vec_add(fOfs,fOrigin,fOrigin)
	
	pev(iPlayer,pev_v_angle,fAngles);
	angle_vector(fAngles,ANGLEVECTOR_FORWARD,fAngles);
	xs_vec_mul_scalar(fAngles, -5.0,fAngles)
	
	pev(iPlayer,pev_v_angle,fAngles2);
	angle_vector(fAngles2,ANGLEVECTOR_UP,fAngles2);
	xs_vec_mul_scalar(fAngles2,10.0,fAngles2)
	
	xs_vec_add(fOrigin,fAngles2,fOrigin)
	xs_vec_add(fOrigin,fAngles,fOrigin);
	
	engfunc(EngFunc_SetOrigin, iEnt, fOrigin)
	
	set_pev(iEnt, pev_solid, SOLID_TRIGGER)
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	set_pev(iEnt, pev_owner,iPlayer)
	
	new Float:fVeloc[3];
	pev(iPlayer,pev_v_angle,fAngles);
	angle_vector(fAngles,ANGLEVECTOR_FORWARD,fAngles);
	xs_vec_normalize(fAngles,fAngles);
	xs_vec_mul_scalar(fAngles,get_pcvar_float(pCvarSpeed),fVeloc)
	set_pev(iEnt,pev_velocity,fVeloc)
	
	//set_pev(iEnt, pev_effects, pev(iEnt, pev_effects) | EF_NODRAW);
	
	attach_view(iPlayer,iEnt);
	
	return iEnt;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
