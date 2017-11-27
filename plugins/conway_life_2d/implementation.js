module.exports = {
  blockUpdaters: (i) => {
    const btLife = i.fetchBlockType("conwayLife2d", "life");
    const btEmpty = i.fetchBlockType("basis", "empty");

    i.implement("spawn", {}, () => {
      return { blockType: btLife };
    });

    i.implement("death", {}, () => {
      return { blockType: btEmpty };
    });
  }
};
