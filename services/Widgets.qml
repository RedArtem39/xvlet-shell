pragma Singleton

import QtQuick
import Quickshell
import qs.services

// The desktop widgets' kinds, as Serpantinum's: each type has faces
// (variants), each face its own size on the 24 px grid; and the ready sets.
Singleton {
    id: root

    readonly property var types: ({
        clock:    { n: "Часы", i: "schedule", v: { lumen: "Люмен", cookie: "Печенье", digital: "Цифры", stretched: "Высокие" } },
        weather:  { n: "Погода", i: "partly_cloudy_day", v: { full: "Полная", round: "Капсула", compact: "Компакт" } },
        music:    { n: "Музыка", i: "album", v: { vinyl: "Винил", card: "Карточка" } },
        cpu:      { n: "Процессор", i: "memory", v: { wave: "Волна", bar: "Полоса" } },
        ram:      { n: "Память", i: "memory_alt", v: { wave: "Волна", bar: "Полоса" } },
        disk:     { n: "Диск", i: "hard_drive", v: { wave: "Волна", bar: "Полоса" } },
        temp:     { n: "Температура", i: "device_thermostat", v: { wave: "Волна", bar: "Полоса" } },
        battery:  { n: "Батарея", i: "battery_5_bar", v: { bar: "Полоса", wave: "Круг" } },
        user:     { n: "Пользователь", i: "account_circle", v: { card: "Карточка" } },
        cal:      { n: "Календарь", i: "calendar_month", v: { month: "Месяц" } },
        notes:    { n: "Заметка", i: "sticky_note_2", v: { note: "Листок" } },
        photo:    { n: "Фото", i: "image", v: { cookie: "Печенье", round: "Круг", rounded: "Скруглённое" } }
    })
    readonly property var sizes: ({
        clock: { lumen: [264, 264], cookie: [264, 264], digital: [288, 312], stretched: [624, 216] },
        weather: { full: [336, 216], round: [216, 216], compact: [240, 96] },
        music: { vinyl: [312, 312], card: [456, 192] },
        cpu: { wave: [144, 144], bar: [264, 96] }, ram: { wave: [144, 144], bar: [264, 96] },
        disk: { wave: [144, 144], bar: [264, 96] }, temp: { wave: [144, 144], bar: [264, 96] },
        battery: { bar: [264, 96], wave: [144, 144] },
        user: { card: [312, 168] }, cal: { month: [336, 336] }, notes: { note: [264, 216] },
        photo: { cookie: [216, 216], round: [216, 216], rounded: [216, 216] }
    })
    function sizeOf(t, v) { return (sizes[t] && sizes[t][v]) || [240, 240]; }
    function firstFace(t) { return Object.keys(types[t].v)[0]; }

    readonly property var sets: ({
        "Обзор": [
            { t: "clock", v: "lumen", x: 1608, y: 96, w: 264, h: 264 }, { t: "weather", v: "full", x: 1536, y: 384, w: 336, h: 216 },
            { t: "cpu", v: "wave", x: 1224, y: 792, w: 144, h: 144 }, { t: "ram", v: "wave", x: 1392, y: 792, w: 144, h: 144 },
            { t: "disk", v: "wave", x: 1560, y: 792, w: 144, h: 144 }, { t: "temp", v: "wave", x: 1728, y: 792, w: 144, h: 144 },
            { t: "battery", v: "bar", x: 1608, y: 648, w: 264, h: 96 }, { t: "user", v: "card", x: 72, y: 96, w: 312, h: 168 }],
        "Медиа": [
            { t: "music", v: "vinyl", x: 120, y: 264, w: 408, h: 408 },
            { t: "clock", v: "stretched", x: 648, y: 120, w: 624, h: 216 }, { t: "weather", v: "round", x: 1632, y: 120, w: 216, h: 216 },
            { t: "photo", v: "cookie", x: 1632, y: 408, w: 216, h: 216 }],
        "Минимум": [
            { t: "clock", v: "digital", x: 72, y: 624, w: 288, h: 312 }, { t: "weather", v: "compact", x: 1608, y: 96, w: 240, h: 96 }]
    })
    function value(t) {
        return t === "cpu" ? Sys.cpu : t === "ram" ? Sys.ram : t === "disk" ? Sys.disk : t === "temp" ? (Sys.temp >= 0 ? Sys.temp / 100 : 0)
            : t === "battery" ? (Power.present ? Power.capacity / 100 : 0) : 0;
    }
    function label(t) { return t === "cpu" ? "Процессор" : t === "ram" ? "Память" : t === "disk" ? "Диск" : t === "temp" ? "Темп." : "Батарея"; }
    function text(t) {
        if (t === "temp") return Sys.temp >= 0 ? Math.round(Sys.temp) + "°" : "нет";
        if (t === "battery") return Power.present ? Power.capacity + "%" : "нет";
        return Math.round(value(t) * 100) + "%";
    }
}
