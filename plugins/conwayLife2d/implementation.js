module.exports = {
  blockUpdaters: (i) => {
    const btLife = i.fetchBlockType("conwayLife2d", "life");
    const btEmpty = i.fetchBlockType("basis", "empty");

    i.blockUpdater("spawn", {}, () => {
      return { blockType: btLife };
    });

    i.blockUpdater("death", {}, () => {
      return { blockType: btEmpty };
    });
  }
};
