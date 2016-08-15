# ===========================
# Immatriculation by Zakharov
# ===========================

var immatNodeName = "/sim/model/c150/immat";

var refresh_immat = func {
    var immat = props.globals.getNode(immatNodeName,1).getValue();
    var immat_size = size(immat);
    if (immat_size != 0) immat = string.uc(immat);
    for (var i = 0; i < 6; i += 1) {
        if (i >= immat_size)
            glyph = -1;
        elsif (string.isupper(immat[i]))
            glyph = immat[i] - `A`;
        elsif (string.isdigit(immat[i]))
            glyph = immat[i] - `0` + 26;
        else
            glyph = 36;
        props.globals.getNode("/sim/multiplay/generic/int["~i~"]", 1).setValue(glyph+1);
    }
}

setlistener("/sim/signals/fdm-initialized", func {
    if (props.globals.getNode(immatNodeName) == nil or props.globals.getNode(immatNodeName).getValue() == '') {
        var immat = props.globals.getNode(immatNodeName,1);
        var callsign = props.globals.getNode("/sim/multiplay/callsign");
        if (callsign != "callsign") immat.setValue(callsign.getValue());
        else immat.setValue("F-C150");
    }
    refresh_immat();
    setlistener(immatNodeName, refresh_immat, 0);
},0);

