#
# Demux topology for cs42888 codec.
#
# PCM0 ----> demux -----> ESAI (cs42888)
# PCM4 <---- demux
#

include(`utils.m4')
include(`dai.m4')
include(`pipeline.m4')
include(`esai.m4')
include(`pcm.m4')
include(`muxdemux.m4')
include(`common/tlv.m4')
include(`sof/tokens.m4')
include(`platform/imx/imx8qxp.m4')

define(matrix1, `ROUTE_MATRIX(1,
			     `BITS_TO_BYTE(1, 0, 0 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 1, 0 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 1 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,1 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,1 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,1 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,0 ,1 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,0 ,0 ,1)')')

define(matrix2, `ROUTE_MATRIX(2,
			     `BITS_TO_BYTE(1, 0, 0 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 1, 0 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 1 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,1 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,1 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,1 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,0 ,1 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,0 ,0 ,1)')')

MUXDEMUX_CONFIG(demux_priv, 2, LIST(`	', `matrix1,', `matrix2'))

PIPELINE_PCM_ADD(sof/pipe-volume-demux-playback.m4,
	1, 0, 2, s24le,
	1000, 0, 0,
	48000, 48000, 48000)

DAI_ADD(sof/pipe-dai-playback.m4,
	1, ESAI, 0, esai0-cs42888,
	PIPELINE_SOURCE_1, 2, s24le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_DMA)

W_DAI_IN(ESAI, 0, esai0-cs42888, s24le, 3, 0)

PIPELINE_PCM_ADD(sof/pipe-passthrough-capture-sched.m4,
	2, 1, 2, s24le,
	1000, 1, 0,
	48000, 48000, 48000,
	SCHEDULE_TIME_DOMAIN_DMA,
	PIPELINE_PLAYBACK_SCHED_COMP_1)

SectionGraph."PIPE_CAP" {
	index "0"

	lines [
		dapm(PIPELINE_SINK_2, PIPELINE_DEMUX_1)
	]
}

SectionGraph."PIPE_CAP_VIRT" {
	index "2"

	lines [
		dapm(ECHO REF 2, ESAI0.IN)
	]
}

PCM_PLAYBACK_ADD(Playback, 0, PIPELINE_PCM_1)
PCM_CAPTURE_ADD(EchoRef, 1, PIPELINE_PCM_2)

DAI_CONFIG(ESAI, 0, 0, esai0-cs42888,
	ESAI_CONFIG(I2S, ESAI_CLOCK(mclk, 49152000, codec_mclk_in),
		ESAI_CLOCK(bclk, 3072000, codec_slave),
		ESAI_CLOCK(fsync, 48000, codec_slave),
		ESAI_TDM(2, 32, 3, 3),
		ESAI_CONFIG_DATA(ESAI, 0, 0)))
