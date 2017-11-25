module.exports = (i) => {
  const btLife = i.fetchBlockType("conwayLife2d", "life");
  const btEmpty = i.fetchBlockType("basis", "empty");

  i.implementBlockUpdater("spawn", {}, () => {
    return { blockType: btLife };
  });

  i.implementBlockUpdater("death", {}, () => {
    return { blockType: btEmpty };
  });
};
