$(function () {
    let isOpen = false;
    let currentLocales = {};
    let soundEnabled = true;

    // ===== SES (Web Audio API) =====
    let audioCtx = null;
    function getCtx() {
        if (!audioCtx) {
            try {
                audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            } catch (e) {
                audioCtx = null;
            }
        }
        return audioCtx;
    }

    function beep(freq, endFreq, duration, vol) {
        const ctx = getCtx();
        if (!ctx) return;
        if (ctx.state === 'suspended') ctx.resume();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, ctx.currentTime);
        if (endFreq) {
            osc.frequency.exponentialRampToValueAtTime(endFreq, ctx.currentTime + duration);
        }
        gain.gain.setValueAtTime(0.0001, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(vol || 0.05, ctx.currentTime + 0.008);
        gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + duration);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + duration + 0.02);
    }

    function playClick() { if (soundEnabled) beep(880, 520, 0.07, 0.05); }
    function playType() { if (soundEnabled) beep(1300, 900, 0.03, 0.03); }

    function cur() {
        const fallback = {
            playerId: "PLAYER ID",
            vehicleCode: "VEHICLE CODE",
            plate: "PLATE",
            plateColor: "PLATE COLOR",
            colors: [
                "White Plate - Blue Text",
                "Black Plate - Yellow Text",
                "Blue Plate - Yellow Text",
                "White Plate - Blue Text 2",
                "White Plate - Blue Text 3",
                "North Yankton"
            ],
            cancel: "CANCEL",
            give: "GIVE VEHICLE",
            errRequired: "Player ID and vehicle code are required.",
            processing: "Processing...",
            vehicleColor: "VEHICLE COLOR",
            vehicleColors: [
                [0, "Black"],
                [1, "Graphite Black"],
                [4, "Silver"],
                [6, "Steel Gray"],
                [7, "Midnight Silver"],
                [8, "Gun Metal"],
                [10, "Red"],
                [13, "Blaze Red"],
                [18, "Candy Red"],
                [21, "Orange"],
                [27, "Ultra Blue"],
                [34, "Dark Green"],
                [35, "Racing Green"],
                [41, "Yellow"],
                [48, "Gold"],
                [53, "White"],
                [54, "Cream"],
                [88, "Matte Black"],
                [111, "Pearl White"]
            ]
        };
        return Object.assign({}, fallback, currentLocales);
    }

    function applyLang() {
        const t = cur();
        $("#targetId").attr("placeholder", t.playerId);
        $("#model").attr("placeholder", t.vehicleCode);
        $("#plate").attr("placeholder", t.plate);
        $("#cancelBtn").html(t.cancel + ' <span class="btn-key">[ESC]</span>');
        $("#giveBtn").html(t.give + ' <span class="btn-key">[ENTER]</span>');

        const sel = $("#plateColor").val();
        $("#plateColorOptions li").each(function (i) {
            $(this).text(t.colors[i]);
        });

        if (sel !== "" && sel !== undefined && sel !== null) {
            $("#plateColorLabel").text(t.colors[parseInt(sel, 10)]);
            $("#plateColorOptions li").removeClass("selected");
            $("#plateColorOptions li[data-value='" + sel + "']").addClass("selected");
        } else {
            $("#plateColorLabel").text(t.plateColor);
            $("#plateColorOptions li").removeClass("selected");
        }

        $("#vehicleColorLabel").text(t.vehicleColor);
    }

    function openUI() {
        isOpen = true;
        $("#nui-container").addClass("active");
        resetResult();
        applyLang();
        setTimeout(() => $("#targetId").focus(), 100);
    }

    function closeUI() {
        isOpen = false;
        $("#nui-container").removeClass("active");
        $("#targetId, #model, #plate").val("");
        resetPlateColor();
        resetVehicleColor();
    }

    function resetResult() {
        const box = $("#resultBox");
        box.removeClass("success error");
        $("#resultText").text("");
    }

    function showResult(success, message) {
        const box = $("#resultBox");
        box.removeClass("success error");
        box.addClass(success ? "success" : "error");
        $("#resultText").text(message);
    }

    function submit() {
        if (!isOpen) return;
        const targetId = $("#targetId").val().trim();
        const model = $("#model").val().trim();
        const plate = $("#plate").val().trim().toUpperCase();
        const plateColor = parseInt($("#plateColor").val(), 10) || 0;
        const vehicleColor = $("#vehicleColor").val() || "255,255,255";

        resetResult();
        $("#resultText").text(cur().processing);

        $.post("https://kasrev-givecar/giveCar", JSON.stringify({
            targetId: targetId,
            model: model,
            plate: plate,
            plateColor: plateColor,
            vehicleColor: vehicleColor
        }), function (resp) {
            if (resp && !resp.success) {
                resetResult();
            }
        });
    }

    // NUI mesajları
    window.addEventListener("message", function (event) {
        const data = event.data;
        if (!data) return;

        if (data.action === "open") {
            if (data.locales) currentLocales = data.locales;
            openUI();
        } else if (data.action === "close") {
            closeUI();
        } else if (data.action === "result") {
            showResult(data.success, data.message);
        }
    });

    // Butonlar
    $("#giveBtn").on("click", function () { playClick(); submit(); });
    $("#cancelBtn").on("click", function () {
        playClick();
        $("#targetId, #model, #plate").val("");
        resetPlateColor();
        resetVehicleColor();
        $.post("https://kasrev-givecar/exit", JSON.stringify({}), function () {});
    });

    // Ses ac/kapa
    $("#soundToggle").on("click", function (e) {
        e.stopPropagation();
        soundEnabled = !soundEnabled;
        $(this).toggleClass("muted", !soundEnabled);
        if (soundEnabled) playClick();
    });

    // Plaka renk acilir kutu
    function resetPlateColor() {
        $("#plateColor").val("");
        $("#plateColorLabel").text(cur().plateColor);
        $("#plateColorOptions li").removeClass("selected");
        $("#plateColorBox").removeClass("open");
    }

    $("#plateColorTrigger").on("click", function (e) {
        e.stopPropagation();
        playClick();
        $("#plateColorBox").toggleClass("open");
    });

    $("#plateColorOptions li").on("click", function (e) {
        e.stopPropagation();
        playClick();
        const val = $(this).data("value");
        const txt = $(this).text();
        $("#plateColor").val(val);
        $("#plateColorLabel").text(txt);
        $("#plateColorOptions li").removeClass("selected");
        if (val !== "") {
            $(this).addClass("selected");
        }
        $("#plateColorBox").removeClass("open");
    });

    // Arac rengi (RGB) paneli
    function applyRGB(r, g, b) {
        r = Math.max(0, Math.min(255, r | 0));
        g = Math.max(0, Math.min(255, g | 0));
        b = Math.max(0, Math.min(255, b | 0));
        const hex = "#" + [r, g, b].map(function (x) {
            return ("0" + x.toString(16)).slice(-2);
        }).join("").toUpperCase();
        $("#vehicleColorPicker").val(hex);
        $("#rgbPreview").css("background", hex);
        $("#vehicleColor").val(r + "," + g + "," + b);
    }

    function rgbFromHex(value) {
        let hex = (value || "").replace("#", "");
        if (hex.length === 3) {
            hex = hex.split("").map(function (c) { return c + c; }).join("");
        }
        if (hex.length !== 6 || /[^0-9a-fA-F]/.test(hex)) return null;
        return [
            parseInt(hex.substr(0, 2), 16),
            parseInt(hex.substr(2, 2), 16),
            parseInt(hex.substr(4, 2), 16)
        ];
    }

    function resetVehicleColor() {
        applyRGB(255, 255, 255);
    }

    $("#vehicleColorHeader").on("click", function () {
        playClick();
        $("#vehicleColorPicker").click();
    });

    $("#rgbPreview").on("click", function (e) {
        e.stopPropagation();
        playType();
    });

    $("#vehicleColorPicker").on("input", function () {
        playType();
        const c = rgbFromHex($(this).val());
        if (c) applyRGB(c[0], c[1], c[2]);
    });

    $(document).on("click", function () {
        $("#plateColorBox").removeClass("open");
    });

    // ESC / ENTER kısayolları
    $(document).on("keydown", function (e) {
        if (!isOpen) return;
        if (e.key === "Escape") {
            $.post("https://kasrev-givecar/exit", JSON.stringify({}), function () {});
        } else if (e.key === "Enter") {
            submit();
        }
    });

    // Input: sadece harf/rakam plakada + canli onizleme
    $("#targetId, #model, #plate").on("input", function () {
        playType();
    });

    $("#plate").on("input", function () {
        this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, "").substring(0, 8);
        $("#platePreview").text(this.value === "" ? "ABC123" : this.value);
    });
});
