import GObject from 'gi://GObject';

import * as utils from '../conveniences/utils.js';
const St = await utils.import_in_shell_only('gi://St');
const Shell = await utils.import_in_shell_only('gi://Shell');
const Clutter = await utils.import_in_shell_only('gi://Clutter');

const SHADER_FILENAME = 'glass_dock.glsl';
const DEFAULT_PARAMS = {
    blur_amount: 1.5,
    distort_strength: 0.001,
    chroma_aberration: 0.002,
    specular_brightness: 0.3,
    brightness_boost: 0.08,
    width: 0,
    height: 0,
};

export const GlassDockEffect = utils.IS_IN_PREFERENCES ?
    { default_params: DEFAULT_PARAMS } :
    new GObject.registerClass({
        GTypeName: "GlassDockEffect",
        Properties: {
            'blur_amount': GObject.ParamSpec.double(
                `blur_amount`,
                `Blur Amount`,
                `Blur radius multiplier`,
                GObject.ParamFlags.READWRITE,
                0.0, 10.0,
                1.5,
            ),
            'distort_strength': GObject.ParamSpec.double(
                `distort_strength`,
                `Distort Strength`,
                `Strength of the noise based distortion`,
                GObject.ParamFlags.READWRITE,
                0.0, 0.02,
                0.001,
            ),
            'chroma_aberration': GObject.ParamSpec.double(
                `chroma_aberration`,
                `Chroma Aberration`,
                `Horizontal offset for RGB split`,
                GObject.ParamFlags.READWRITE,
                0.0, 0.02,
                0.002,
            ),
            'specular_brightness': GObject.ParamSpec.double(
                `specular_brightness`,
                `Specular Brightness`,
                `Intensity of the specular highlight`,
                GObject.ParamFlags.READWRITE,
                0.0, 1.0,
                0.3,
            ),
            'brightness_boost': GObject.ParamSpec.double(
                `brightness_boost`,
                `Brightness Boost`,
                `Overall brightness boost for the glass effect`,
                GObject.ParamFlags.READWRITE,
                0.0, 0.5,
                0.08,
            ),
            'width': GObject.ParamSpec.double(
                `width`,
                `Width`,
                `Actor width`,
                GObject.ParamFlags.READWRITE,
                0.0, Number.MAX_SAFE_INTEGER,
                0.0,
            ),
            'height': GObject.ParamSpec.double(
                `height`,
                `Height`,
                `Actor height`,
                GObject.ParamFlags.READWRITE,
                0.0, Number.MAX_SAFE_INTEGER,
                0.0,
            ),
        }
    }, class GlassDockEffect extends Clutter.ShaderEffect {
        constructor(params) {
            super(params);

            utils.setup_params(this, params);

            // set shader source
            this._source = utils.get_shader_source(Shell, SHADER_FILENAME, import.meta.url);
            if (this._source)
                this.set_shader_source(this._source);
        }

        static get default_params() {
            return DEFAULT_PARAMS;
        }

        /* --- Blur amount --- */
        get blur_amount() {
            return this._blur_amount;
        }
        set blur_amount(value) {
            if (this._blur_amount !== value) {
                this._blur_amount = value;
                this.set_uniform_value('u_blurAmount', parseFloat(this._blur_amount - 1e-6));
            }
        }

        /* --- Distort strength --- */
        get distort_strength() {
            return this._distort_strength;
        }
        set distort_strength(value) {
            if (this._distort_strength !== value) {
                this._distort_strength = value;
                this.set_uniform_value('u_distortStrength', parseFloat(this._distort_strength - 1e-6));
            }
        }

        /* --- Chroma aberration --- */
        get chroma_aberration() {
            return this._chroma_aberration;
        }
        set chroma_aberration(value) {
            if (this._chroma_aberration !== value) {
                this._chroma_aberration = value;
                this.set_uniform_value('u_chromaAberration', parseFloat(this._chroma_aberration - 1e-6));
            }
        }

        /* --- Specular brightness --- */
        get specular_brightness() {
            return this._specular_brightness;
        }
        set specular_brightness(value) {
            if (this._specular_brightness !== value) {
                this._specular_brightness = value;
                this.set_uniform_value('u_specularBrightness', parseFloat(this._specular_brightness - 1e-6));
            }
        }

        /* --- Brightness boost --- */
        get brightness_boost() {
            return this._brightness_boost;
        }
        set brightness_boost(value) {
            if (this._brightness_boost !== value) {
                this._brightness_boost = value;
                this.set_uniform_value('u_brightnessBoost', parseFloat(this._brightness_boost - 1e-6));
            }
        }

        /* --- Width & Height --- */
        get width() {
            return this._width;
        }
        set width(value) {
            if (this._width !== value) {
                this._width = value;
                this.set_uniform_value('width', parseFloat(this._width - 1e-6));
            }
        }

        get height() {
            return this._height;
        }
        set height(value) {
            if (this._height !== value) {
                this._height = value;
                this.set_uniform_value('height', parseFloat(this._height - 1e-6));
            }
        }

        vfunc_set_actor(actor) {
            if (this._actor_connection_size_id) {
                let old_actor = this.get_actor();
                old_actor?.disconnect(this._actor_connection_size_id);
            }
            if (actor) {
                this.width = actor.width;
                this.height = actor.height;
                this._actor_connection_size_id = actor.connect('notify::size', _ => {
                    this.width = actor.width;
                    this.height = actor.height;
                });
            } else {
                this._actor_connection_size_id = null;
            }
            super.vfunc_set_actor(actor);
        }
    }); 