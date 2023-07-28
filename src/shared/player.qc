/*
 * Copyright (c) 2016-2021 Marco Cawthorne <marco@icculus.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
 * IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include "../../../valve/src/shared/skeleton.h"

/* all potential SendFlags bits we can possibly send */
enumflags
{
	PLAYER_TOPFRAME = PLAYER_CUSTOMFIELDSTART,
	PLAYER_BOTTOMFRAME,
	PLAYER_AMMO1,
	PLAYER_AMMO2,
	PLAYER_AMMO3,
	PLAYER_UNUSED5,
	PLAYER_UNUSED6,
	PLAYER_UNUSED7
};

class
player:NSClientPlayer
{
	PREDICTED_INT(anim_top)
	PREDICTED_FLOAT(anim_top_time)
	PREDICTED_FLOAT(anim_top_delay)
	PREDICTED_INT(anim_bottom)
	PREDICTED_FLOAT(anim_bottom_time)

	PREDICTED_INT(bradnailer_mag)
	PREDICTED_INT(nailgun_mag)
	PREDICTED_INT(shotgun_mag)
	PREDICTED_INT(cmlwbr_mag)
	PREDICTED_INT(xs_mag)
	PREDICTED_INT(satchel_chg)

	PREDICTED_INT(ammo_nail)
	PREDICTED_INT(ammo_buckshot)
	PREDICTED_INT(ammo_bolts)
	PREDICTED_INT(ammo_xencandy)
	PREDICTED_INT(ammo_satchel)
	PREDICTED_INT(mode_tempstate)

#ifdef CLIENT
	virtual void(float,float) ReceiveEntity;
	virtual void(void) PredictPreFrame;
	virtual void(void) PredictPostFrame;
#else
	virtual void(void) EvaluateEntity;
	virtual float(entity, float) SendEntity;
#endif
};

#ifdef CLIENT
void Weapons_AmmoUpdate(entity);
void HUD_AmmoNotify_Check(player pl);
void HUD_ItemNotify_Check(player pl);
/*
=================
player::ReceiveEntity
=================
*/
void
player::ReceiveEntity(float new, float fl)
{
	NSClientPlayer::ReceiveEntity(new, fl);

	/* animation */
	if (fl & PLAYER_TOPFRAME) {
		anim_top = readbyte();
		anim_top_time = readfloat();
		anim_top_delay = readfloat();
	}
	if (fl & PLAYER_BOTTOMFRAME) {
		anim_bottom = readbyte();
		anim_bottom_time = readfloat();
	}

	if (fl & PLAYER_AMMO1) {
		bradnailer_mag = readbyte();
		nailgun_mag = readbyte();
		shotgun_mag = readbyte();
		cmlwbr_mag = readbyte();
		xs_mag = readbyte();
		satchel_chg = readbyte();
	}
	
	if (fl & PLAYER_AMMO2) {
		ammo_nail = readbyte();
		ammo_buckshot = readbyte();
		ammo_bolts = readbyte();
		ammo_xencandy = readbyte();
		ammo_satchel = readbyte();
	}

	if (fl & PLAYER_AMMO3) {
		mode_tempstate = readbyte();
	}

	setorigin(this, origin);

	/* these only concern the current player */
	CSQC_UpdateSeat();
	if (this != pSeat->m_ePlayer)
		return;

	/* do not notify us of updates when spawning initially */
	if (fl == UPDATE_ALL)
		PredictPreFrame();

	if (fl & PLAYER_AMMO1 || fl & PLAYER_AMMO2 || fl & PLAYER_AMMO3) {
		Weapons_AmmoUpdate(this);
		HUD_AmmoNotify_Check(this);
	}

	if (fl & PLAYER_ITEMS || fl & PLAYER_HEALTH)
		HUD_ItemNotify_Check(this);
}

/*
=================
player::PredictPostFrame

Save the last valid server values away in the _net variants of each field
so we can roll them back later.
=================
*/
void
player::PredictPreFrame(void)
{
	NSClientPlayer::PredictPreFrame();

	SAVE_STATE(anim_top);
	SAVE_STATE(anim_top_time);
	SAVE_STATE(anim_top_delay);
	SAVE_STATE(anim_bottom);
	SAVE_STATE(anim_bottom_time);

	SAVE_STATE(bradnailer_mag);
	SAVE_STATE(nailgun_mag);
	SAVE_STATE(shotgun_mag);
	SAVE_STATE(cmlwbr_mag);
	SAVE_STATE(xs_mag);
	SAVE_STATE(satchel_chg);

	SAVE_STATE(ammo_nail);
	SAVE_STATE(ammo_buckshot);
	SAVE_STATE(ammo_bolts);
	SAVE_STATE(ammo_xencandy);
	SAVE_STATE(ammo_satchel);
	SAVE_STATE(mode_tempstate);
}

/*
=================
player::PredictPostFrame

Where we roll back our values to the ones last sent/verified by the server.
=================
*/
void
player::PredictPostFrame(void)
{
	NSClientPlayer::PredictPostFrame();

	ROLL_BACK(anim_top);
	ROLL_BACK(anim_top_time);
	ROLL_BACK(anim_top_delay);
	ROLL_BACK(anim_bottom);
	ROLL_BACK(anim_bottom_time);

	ROLL_BACK(bradnailer_mag);
	ROLL_BACK(nailgun_mag);
	ROLL_BACK(shotgun_mag);
	ROLL_BACK(cmlwbr_mag);
	ROLL_BACK(xs_mag);
	ROLL_BACK(satchel_chg);

	ROLL_BACK(ammo_nail);
	ROLL_BACK(ammo_buckshot);
	ROLL_BACK(ammo_bolts);
	ROLL_BACK(ammo_xencandy);
	ROLL_BACK(ammo_satchel);
	ROLL_BACK(mode_tempstate);
}

#else
void
player::EvaluateEntity(void)
{
	NSClientPlayer::EvaluateEntity();

	/* animation */
	if (ATTR_CHANGED(anim_bottom) || ATTR_CHANGED(anim_bottom_time))
		SendFlags |= PLAYER_BOTTOMFRAME;
	if (ATTR_CHANGED(anim_top) || ATTR_CHANGED(anim_top_time) || ATTR_CHANGED(anim_top_delay))
		SendFlags |= PLAYER_TOPFRAME;

	if (ATTR_CHANGED(bradnailer_mag))
		SendFlags |= PLAYER_AMMO1;
	if (ATTR_CHANGED(nailgun_mag))
		SendFlags |= PLAYER_AMMO1;
	if (ATTR_CHANGED(shotgun_mag))
		SendFlags |= PLAYER_AMMO1;
	if (ATTR_CHANGED(cmlwbr_mag))
		SendFlags |= PLAYER_AMMO1;
	if (ATTR_CHANGED(xs_mag))
		SendFlags |= PLAYER_AMMO1;
	if (ATTR_CHANGED(satchel_chg))
		SendFlags |= PLAYER_AMMO1;

	if (ATTR_CHANGED(ammo_nail))
		SendFlags |= PLAYER_AMMO2;
	if (ATTR_CHANGED(ammo_buckshot))
		SendFlags |= PLAYER_AMMO2;
	if (ATTR_CHANGED(ammo_bolts))
		SendFlags |= PLAYER_AMMO2;
	if (ATTR_CHANGED(ammo_xencandy))
		SendFlags |= PLAYER_AMMO2;
	if (ATTR_CHANGED(ammo_satchel))
		SendFlags |= PLAYER_AMMO2;

	if (ATTR_CHANGED(mode_tempstate))
		SendFlags |= PLAYER_AMMO3;

	SAVE_STATE(anim_top);
	SAVE_STATE(anim_top_time);
	SAVE_STATE(anim_top_delay);
	SAVE_STATE(anim_bottom);
	SAVE_STATE(anim_bottom_time);

	SAVE_STATE(bradnailer_mag);
	SAVE_STATE(nailgun_mag);
	SAVE_STATE(shotgun_mag);
	SAVE_STATE(cmlwbr_mag);
	SAVE_STATE(xs_mag);
	SAVE_STATE(satchel_chg);

	SAVE_STATE(ammo_nail);
	SAVE_STATE(ammo_buckshot);
	SAVE_STATE(ammo_bolts);
	SAVE_STATE(ammo_xencandy);
	SAVE_STATE(ammo_satchel);
	SAVE_STATE(mode_tempstate);
}

/*
=================
player::SendEntity
=================
*/
float
player::SendEntity(entity ePEnt, float flChanged)
{
	/* don't broadcast invisible players */
	if (IsFakeSpectator() && ePEnt != this)
		return (0);
	if (!GetModelindex() && ePEnt != this)
		return (0);

	flChanged = OptimiseChangedFlags(ePEnt, flChanged);

	WriteByte(MSG_ENTITY, ENT_PLAYER);
	WriteFloat(MSG_ENTITY, flChanged);

	NSClientPlayer::SendEntity(ePEnt, flChanged);

	if (flChanged & PLAYER_TOPFRAME) {
		WriteByte(MSG_ENTITY, anim_top);
		WriteFloat(MSG_ENTITY, anim_top_time);
		WriteFloat(MSG_ENTITY, anim_top_delay);
	}
	if (flChanged & PLAYER_BOTTOMFRAME) {
		WriteByte(MSG_ENTITY, anim_bottom);
		WriteFloat(MSG_ENTITY, anim_bottom_time);
	}

	if (flChanged & PLAYER_AMMO1) {
		WriteByte(MSG_ENTITY, bradnailer_mag);
		WriteByte(MSG_ENTITY, nailgun_mag);
		WriteByte(MSG_ENTITY, shotgun_mag);
		WriteByte(MSG_ENTITY, cmlwbr_mag);
		WriteByte(MSG_ENTITY, xs_mag);
		WriteByte(MSG_ENTITY, satchel_chg);
	}
	
	if (flChanged & PLAYER_AMMO2) {
		WriteByte(MSG_ENTITY, ammo_nail);
		WriteByte(MSG_ENTITY, ammo_buckshot);
		WriteByte(MSG_ENTITY, ammo_bolts);
		WriteByte(MSG_ENTITY, ammo_xencandy);
		WriteByte(MSG_ENTITY, ammo_satchel);
	}

	if (flChanged & PLAYER_AMMO3) {
		WriteByte(MSG_ENTITY, mode_tempstate);
	}

	return (1);
}
#endif
